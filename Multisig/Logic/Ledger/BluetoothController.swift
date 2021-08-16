//
//  BluetoothController.swift
//  Multisig
//
//  Created by Moaaz on 7/26/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreBluetooth

// should be class
class BluetoothDevice {
    let peripheral: CBPeripheral
    var name: String {
        peripheral.name ?? "Unknown device"
    }

    var readCharacteristic: CBCharacteristic? = nil
    var writeCharacteristic: CBCharacteristic? = nil
    var notifyCharacteristic: CBCharacteristic? = nil

    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
    }
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

protocol BluetoothControllerDelegate: AnyObject {
    func bluetoothControllerDidFailToConnectBluetooth(error: DetailedLocalizedError)
    func bluetoothControllerDidDiscover(device: BluetoothDevice)
    func bluetoothControllerDidDisconnect(device: BluetoothDevice, error: DetailedLocalizedError?)
}

class BluetoothController: NSObject {
    private var centralManager: CBCentralManager!
    weak var delegate: BluetoothControllerDelegate?

    typealias WriteCommand = () -> Void
    private var writeCommands = [UUID: WriteCommand]()

    typealias ResponseCompletion = (Result<Data, Error>) -> Void
    private var responses = [UUID: ResponseCompletion]()


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

    func deviceFor(deviceId: UUID) -> BluetoothDevice? {
        devices.first { p in p.peripheral.identifier == deviceId }
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
        if deviceFor(deviceId: peripheral.identifier) == nil {
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
        guard let device = deviceFor(deviceId: peripheral.identifier) else { return }
        let detailedError: DetailedLocalizedError? =
            error == nil ? nil : GSError.error(description: "AR Bluetooth device disconnected", error: error!)
        devices.removeAll { p in p.peripheral == peripheral }
        delegate?.bluetoothControllerDidDisconnect(device: device, error: detailedError)
    }

    func sendCommand(device: BluetoothDevice, command: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        centralManager.connect(device.peripheral, options: nil)
        writeCommands[device.peripheral.identifier] = { [weak self] in
            let adpuData = APDUController.prepareADPU(message: command)
            self?.responses[device.peripheral.identifier] = completion
            device.peripheral.writeValue(adpuData, for: device.writeCharacteristic!, type: .withResponse)
        }
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
                deviceFor(deviceId: peripheral.identifier)!.readCharacteristic = characteristic
            }

            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                deviceFor(deviceId: peripheral.identifier)!.notifyCharacteristic = characteristic
            }

            if characteristic.properties.contains(.write) {
                peripheral.setNotifyValue(true, for: characteristic)
                deviceFor(deviceId: peripheral.identifier)!.writeCharacteristic = characteristic

                if let writeCommand = writeCommands[peripheral.identifier] {
                    writeCommand()
                    writeCommands.removeValue(forKey: peripheral.identifier)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if supportedDeviceNotifyUuids.contains(characteristic.uuid) {
            // skip if response is not awaited anymore
            guard let responseCompletion = responses[peripheral.identifier] else { return }

            if let error = error {
                LogService.shared.info("Failed to connect with bluetooth device", error: error)
                responseCompletion(.failure(error))
            }
            if let message = characteristic.value, let data = APDUController.parseADPU(message: message) {
                responseCompletion(.success(data))
            } else {
                LogService.shared.error(
                    "Could not parse ADPU for message: \(characteristic.value?.toHexString() ?? "nil")")
                responseCompletion(.failure(""))
            }
            
            responses.removeValue(forKey: peripheral.identifier)
        }
    }
}
