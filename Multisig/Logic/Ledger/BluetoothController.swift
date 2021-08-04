//
//  BluetoothController.swift
//  Multisig
//
//  Created by Moaaz on 7/26/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreBluetooth

struct BluetoothDevice {
    let peripheral: CBPeripheral
    var name: String {
        peripheral.name ?? "Unknown device"
    }

    var readCharacteristic: CBCharacteristic? = nil
    var writeCharacteristic: CBCharacteristic? = nil
    var notifyCharacteristic: CBCharacteristic? = nil
}

protocol SupportedDevice {
    var uuid: CBUUID { get }
    var notifyUuid: CBUUID { get }
    var writeUuid: CBUUID { get }
}

struct LedgerNanoXDevice: SupportedDevice {
    var uuid: CBUUID { CBUUID(string: "13d63400-2c97-0004-0000-4c6564676572") }
    var notifyUuid: CBUUID { CBUUID(string: "13D63400-2C97-0004-0001-4C6564676572") }
    var writeUuid: CBUUID { CBUUID(string: "13d63400-2c97-0004-0002-4c6564676572") }
}

protocol BluetoothControllerDelegate {
    func bluetoothControllerDidReceive(response: Data, device: BluetoothDevice)
    func bluetoothControllerDidFailToConnectBluetooth(error: Error)
    func bluetoothControllerDidDiscover(device: BluetoothDevice)
    func bluetoothControllerDidDisconnect(device: BluetoothDevice, error: Error?)
    func bluetoothControllerDataToSend(device: BluetoothDevice) -> Data?
}

class BluetoothController: NSObject {
    private var centralManager: CBCentralManager!
    var delegate: BluetoothControllerDelegate?

    var devices: [BluetoothDevice] = []

    private var supportedDevices: [SupportedDevice] = []
    private var supportedDeviceUUIDs: [CBUUID] { supportedDevices.compactMap { $0.uuid } }
    private var supportedDeviceNotifyUuids: [CBUUID] { supportedDevices.compactMap { $0.notifyUuid } }

    func scan(supportedDevices: [SupportedDevice] = [LedgerNanoXDevice()]) {
        devices = []
        self.supportedDevices = supportedDevices
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func stopScan() {
        centralManager.stopScan()
    }
}

extension BluetoothController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: supportedDeviceUUIDs)
        default:
            delegate?.bluetoothControllerDidFailToConnectBluetooth(error: GSError.ProblemConnectingBluetoothDevice())
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if deviceFor(peripheral: peripheral) == nil {
            let device = BluetoothDevice(peripheral: peripheral)
            devices.append(device)
            delegate?.bluetoothControllerDidDiscover(device: device)
        }

        centralManager.stopScan()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(supportedDeviceUUIDs)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let device = deviceFor(peripheral: peripheral) {
            delegate?.bluetoothControllerDidDisconnect(device: device, error: error)
        }
        devices.removeAll { p in p.peripheral == peripheral }
    }
}

extension BluetoothController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services { peripheral.discoverCharacteristics(nil, for: service) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
                devices[indexFor(peripheral: peripheral)!].readCharacteristic = characteristic
            }

            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                devices[indexFor(peripheral: peripheral)!].notifyCharacteristic = characteristic
            }

            if characteristic.properties.contains(.write) {
                peripheral.setNotifyValue(true, for: characteristic)
                devices[indexFor(peripheral: peripheral)!].writeCharacteristic = characteristic
                if let data = delegate?.bluetoothControllerDataToSend(device: devices[indexFor(peripheral: peripheral)!]) {
                    peripheral.writeValue(data, for: characteristic, type: .withResponse)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            LogService.shared.error("Failed to connect with bluetooth device", error: error)
        }

        if supportedDeviceNotifyUuids.contains(characteristic.uuid) {
            if let data = characteristic.value {
                delegate?.bluetoothControllerDidReceive(response: data,
                                                        device: devices[indexFor(peripheral: peripheral)!])
            }
        }
    }

    private func write(device: BluetoothDevice, data: Data) {
        guard let writeCharacteristic = device.writeCharacteristic else { return }
        device.peripheral.writeValue(data, for: writeCharacteristic, type: .withResponse)
    }

    func sendCommand(device: BluetoothDevice) {
        centralManager.connect(device.peripheral, options: nil)
    }

    private func deviceFor(peripheral: CBPeripheral) -> BluetoothDevice? {
        devices.first { p in p.peripheral == peripheral }
    }

    private func indexFor(peripheral: CBPeripheral) -> Int? {
        devices.firstIndex{ p in p.peripheral == peripheral }
    }
}
