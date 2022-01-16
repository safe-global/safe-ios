//
//  BluetoothController.swift
//  Multisig
//
//  Created by Moaaz on 7/26/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreBluetooth

class BaseBluetoothDevice {
    var identifier: UUID { preconditionFailure() }
    var name: String { preconditionFailure() }
}

class BluetoothDevice: BaseBluetoothDevice {
    let peripheral: CBPeripheral

    override var name: String {
        peripheral.name ?? "Unknown device"
    }

    override var identifier: UUID {
        peripheral.identifier
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
    func bluetoothControllerDidDiscover(device: BaseBluetoothDevice)
    func bluetoothControllerDidDisconnect(device: BaseBluetoothDevice, error: DetailedLocalizedError?)
}

class BaseBluetoothController: NSObject {
    // Notified about discovery and connection/disconnection status
    weak var delegate: BluetoothControllerDelegate?

    // List of discovered devices
    var devices: [BaseBluetoothDevice] = []

    // Starts scanning process. This may result in calling of delegate's didDiscover methods
    // several times for each device discovered.
    func scan() {
        preconditionFailure()
    }

    // Stops scanning for bluetooth devices
    func stopScan() {
        preconditionFailure()
    }

    // Returns a device by device id from the list of discovered devices
    func deviceFor(deviceId: UUID) -> BaseBluetoothDevice? {
        devices.first { $0.identifier == deviceId }
    }

    // Sends asynchronous command to the device and gets called back via completion.
    // Commands are binary data
    func sendCommand(device: BaseBluetoothDevice, command: Data, index: UInt16 = 0, completion: @escaping (Result<Data, Error>) -> Void) {
        preconditionFailure()
    }

    func sendCommand(device: BaseBluetoothDevice, commands: [Data], completion: @escaping (Result<Data, Error>) -> Void) {
        preconditionFailure()
    }

}

class BluetoothController: BaseBluetoothController {
    private var centralManager: CBCentralManager!

    typealias WriteCommand = () -> Void
    private var writeCommands = [UUID: WriteCommand]()

    typealias ResponseCompletion = (Result<Data, Error>) -> Void
    private var responses = [UUID: ResponseCompletion]()

    private var supportedDevices: [SupportedDevice] = [LedgerNanoXDevice()]
    private var supportedDeviceUUIDs: [CBUUID] { supportedDevices.compactMap { $0.uuid } }
    private var supportedDeviceNotifyUuids: [CBUUID] { supportedDevices.compactMap { $0.notifyUuid } }

    override func scan() {
        devices = []
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func stopScan() {
        centralManager.stopScan()
    }

    func removeDevices(peripheral: CBPeripheral) {
        devices.removeAll { d in
            if let device = d as? BluetoothDevice {
                return device.peripheral == peripheral
            }
            return false
        }
    }

    func bluetoothDevice(id: UUID) -> BluetoothDevice? {
        deviceFor(deviceId: id) as? BluetoothDevice
    }

    override func sendCommand(device: BaseBluetoothDevice, command: Data, index: UInt16 = 0, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let device = device as? BluetoothDevice else {
            preconditionFailure("Expecting bluetooth device")
        }
        centralManager.connect(device.peripheral, options: nil)
        writeCommands[device.peripheral.identifier] = { [weak self] in

            let packetSequenceIndex = withUnsafeBytes(of: index.bigEndian, Array.init)
            let apduLen = withUnsafeBytes(of: UInt16(command.count).bigEndian, Array.init)

            let transportData: Data = Data([
                // Communication channel ID 0101 - A similar encoding is used over BLE, without the Communication channel ID. not needed
                // 0x01, 0x01,
                // command tag - TAG_ADPU (0x05)
                0x05,
            ]) +
            // packet sequence index (big endian) - uint16
            Data(packetSequenceIndex) +
            // payload - variable
            // apdu length
            Data(apduLen) +
            // APDU
            command

            self?.responses[device.peripheral.identifier] = completion
            device.peripheral.writeValue(transportData, for: device.writeCharacteristic!, type: .withResponse)
        }
    }

    override func sendCommand(device: BaseBluetoothDevice, commands: [Data], completion: @escaping (Result<Data, Error>) -> Void) {
        guard let device = device as? BluetoothDevice else {
            preconditionFailure("Expecting bluetooth device")
        }
        centralManager.connect(device.peripheral, options: nil)
        writeCommands[device.peripheral.identifier] = { [weak self] in
            self?.responses[device.peripheral.identifier] = completion

            for (index, command) in commands.enumerated() {
                let apduData = APDUController.prepareAPDU(message: command)
                let isLast = index == commands.count - 1
                device.peripheral.writeValue(apduData, for: device.writeCharacteristic!, type: .withResponse)
            }
        }
    }
}

extension BluetoothController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager.retrieveConnectedPeripherals(withServices: supportedDeviceUUIDs).forEach { peripheral in
                didDiscoverDevice(peripheral)
            }
            centralManager.scanForPeripherals(withServices: supportedDeviceUUIDs)
        case .unauthorized:
            delegate?.bluetoothControllerDidFailToConnectBluetooth(error: GSError.BluetoothIsNotAuthorized())
        default:
            delegate?.bluetoothControllerDidFailToConnectBluetooth(error: GSError.ProblemConnectingBluetoothDevice())
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        didDiscoverDevice(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(supportedDeviceUUIDs)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let device = deviceFor(deviceId: peripheral.identifier) else { return }
        let detailedError: DetailedLocalizedError? =
            error == nil ? nil : GSError.error(description: "The Bluetooth device disconnected", error: error!)
        removeDevices(peripheral: peripheral)

        responses.forEach { deviceId, completion in
            completion(.failure("The Bluetooth device disconnected"))
        }

        delegate?.bluetoothControllerDidDisconnect(device: device, error: detailedError)
    }

    func didDiscoverDevice(_ peripheral: CBPeripheral) {
        if deviceFor(deviceId: peripheral.identifier) == nil {
            let device = BluetoothDevice(peripheral: peripheral)
            devices.append(device)
            delegate?.bluetoothControllerDidDiscover(device: device)
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
                bluetoothDevice(id: peripheral.identifier)!.readCharacteristic = characteristic
            }

            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                bluetoothDevice(id: peripheral.identifier)!.notifyCharacteristic = characteristic
            }

            if characteristic.properties.contains(.write) {
                peripheral.setNotifyValue(true, for: characteristic)
                bluetoothDevice(id: peripheral.identifier)!.writeCharacteristic = characteristic

                if let writeCommand = writeCommands[peripheral.identifier] {
                    writeCommand()
                    writeCommands.removeValue(forKey: peripheral.identifier)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("BLE:", peripheral, characteristic, error)
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("BLE:", peripheral)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("BLE:", peripheral, characteristic, error)

        if let error = error {
            LogService.shared.info("Failed to connect with bluetooth device", error: error)
        }
        if let message = characteristic.value, let data = APDUController.parseAPDU(message: message) {
            print("APDU data: \(data)")
        } else {
            LogService.shared.error(
                "Could not parse APDU for message: \(characteristic.value?.toHexString() ?? "nil")")
        }

        if let d = characteristic.value, let str = String(data: d, encoding: .utf8) {
            print("Message: ", str)
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
            if let message = characteristic.value, let data = APDUController.parseAPDU(message: message) {
                responseCompletion(.success(data))
            } else {
                LogService.shared.error(
                    "Could not parse APDU for message: \(characteristic.value?.toHexString() ?? "nil")")
                responseCompletion(.failure(""))
            }
            
            responses.removeValue(forKey: peripheral.identifier)
        }
    }
}


class SimulatedLedgerDevice: BaseBluetoothDevice {
    let deviceID = UUID()
    let deviceName = "Simulated Ledger Nano X"

    override var identifier: UUID { deviceID }
    override var name: String { deviceName }
}

class SimulatedBluetoothController: BaseBluetoothController {
    override init() {
        super.init()
        devices = [SimulatedLedgerDevice()]
    }

    override func scan() {
        // immediately discover
        delegate?.bluetoothControllerDidDiscover(device: devices[0])
    }

    override func stopScan() {
        // do nothing
    }

    var keys: [Address: PrivateKey] = [:]

    override func sendCommand(device: BaseBluetoothDevice, command: Data, index: UInt16 = 0, completion: @escaping (Result<Data, Error>) -> Void) {
        DispatchQueue.global().async {
            // get address command
            if command.starts(with: [0xe0, 0x02]) {
                // generate random address and return the expected payload in completion

                var address: Address!
                repeat {
                    address = Data.randomBytes(length: 20).flatMap { Address($0) }
                } while address == nil

                // format payload
                let fakePublicKey = [UInt8](repeating: 1, count: 65)
                let hexAddress = address.data.toHexString().data(using: .ascii)!

                let response: [UInt8] =
                    [UInt8(fakePublicKey.count)] + fakePublicKey +
                    [UInt8(hexAddress.count)] + hexAddress

                assert(response.count == 107)
                assert(response[0] == 65)
                assert(response[66] == 40)

                DispatchQueue.main.async {
                    completion(.success(Data(response)))
                }
            } else if command.starts(with: [0xe0, 0x08]) {
                // sign command

                let response = Data([UInt8](repeating: 3, count: 65))

                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    completion(.success(response))
                }

            } else {

                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    completion(.failure("Failed to do the command"))
                }
            }
        }
    }
}
