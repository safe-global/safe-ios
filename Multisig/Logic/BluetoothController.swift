//
//  BluetoothController.swift
//  Multisig
//
//  Created by Moaaz on 7/26/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol LedgerNanoXControllerDelegate {
    func bluetoothControllerDidReceive(response: String)
    func bluetoothControllerDidFailToConnectBluetooth()
    func bluetoothControllerDidDiscoverDevice()
    func bluetoothControllerDidDisconnectDevice()
}

class BluetoothController: NSObject {
    static let shared = BluetoothController()
    private var centralManager: CBCentralManager!
    var delegate: LedgerNanoXControllerDelegate?

    private var devices: [BluetoothDevice] = []
    private var supportedDevices: [DeviceConstant] = []

    private var supportedDeviceUuids: [CBUUID] { supportedDevices.compactMap { $0.uuid } }
    private var supportedDeviceNotifyUuids: [CBUUID] { supportedDevices.compactMap { $0.notifyUuid } }

    override init() {
        super.init()
    }

    func scan(devices: [DeviceConstant]) {
        supportedDevices = devices
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
            centralManager.scanForPeripherals(withServices: supportedDeviceUuids)
        default:
            // Bluetooth might be off or not permitted to use
            delegate?.bluetoothControllerDidFailToConnectBluetooth()
            break
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if deviceFor(peripheral: peripheral) == nil {
            devices.append(BluetoothDevice(peripheral: peripheral))
            delegate?.bluetoothControllerDidDiscoverDevice()
        }

        centralManager.stopScan()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(supportedDeviceUuids)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        devices.removeAll { p in p.peripheral == peripheral }
        delegate?.bluetoothControllerDidDisconnectDevice()
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
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }

        if supportedDeviceNotifyUuids.contains(characteristic.uuid) {
            // 
        }
    }

    private func write(device: BluetoothDevice, data: Data) {
        guard let writeCharacteristic = device.writeCharacteristic else { return }
        device.peripheral.writeValue(Data(), for: writeCharacteristic, type: .withResponse)
    }

    func sendCommand(device: BluetoothDevice, complition: ([String]) -> ()) {
        centralManager.connect(device.peripheral, options: nil)
    }

    private func deviceFor(peripheral: CBPeripheral) -> BluetoothDevice? {
        devices.first { p in p.peripheral == peripheral }
    }

    private func indexFor(peripheral: CBPeripheral) -> Int? {
        devices.firstIndex{ p in p.peripheral == peripheral }
    }
}

struct BluetoothDevice {
    let peripheral: CBPeripheral
    var name: String {
        peripheral.name ?? "Unknown device"
    }

    var readCharacteristic: CBCharacteristic? = nil
    var writeCharacteristic: CBCharacteristic? = nil
    var notifyCharacteristic: CBCharacteristic? = nil
}

enum DeviceConstant {
    case ledgerNanoX

    var uuid: CBUUID { CBUUID(string: "13d63400-2c97-0004-0000-4c6564676572") }
    var notifyUuid: CBUUID { CBUUID(string: "13D63400-2C97-0004-0001-4C6564676572") }
    var WriteUuid: CBUUID { CBUUID(string: "13d63400-2c97-0004-0002-4c6564676572") }
}
