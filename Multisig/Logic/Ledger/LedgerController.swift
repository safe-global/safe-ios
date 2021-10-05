//
//  LedgerCommandController.swift
//  Multisig
//
//  Created by Moaaz on 7/28/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class LedgerController {
    let bluetoothController: BluetoothController

    init(bluetoothController: BluetoothController) {
        self.bluetoothController = bluetoothController
    }

    func getAddress(deviceId: UUID, path: String, completion: @escaping (Address?) -> Void) {
        guard let device = bluetoothController.deviceFor(deviceId: deviceId) else {
            completion(nil)
            return
        }

        let command = getAddressCommand(path: path)

        // We don't use [weak self] with private methods not to capture LedgerController in a caller
        bluetoothController.sendCommand(device: device, command: command) { result in
            switch result {
            case .success(let data):
                guard data.count == 109,
                      Int(data[5]) == 65, // public key length
                      Int(data[71]) == 40 // address length
                else {
                    completion(nil)
                    return
                }

                let addressData = data[(6 + 65 + 1)..<(6 + 65 + 1 + 40)]

                guard let addressString = String(data: addressData, encoding: .ascii),
                      let address =  Address(addressString) else {
                    completion(nil)
                    return
                }
                
                completion(address)
            case .failure(_):
                completion(nil)
            }
        }
    }

    typealias SignatureCompletion = (_ signature: String?, _ errorMessage: String?) -> Void

    func sign(safeTxHash: String, deviceId: UUID, path: String, completion: @escaping SignatureCompletion) {
        guard let device = bluetoothController.deviceFor(deviceId: deviceId) else {
            completion(nil, "Device not found")
            return
        }
        let command = signMessageCommand(path: path, messageHash: safeTxHash)

        // We don't use [weak self] with private methods not to capture LedgerController in a caller
        bluetoothController.sendCommand(device: device, command: command) { result in
            switch result {
            case .success(let data):
                // https://github.com/LedgerHQ/ledgerjs/blob/c329fe63f6f640a9f4c2f200a788fa845547e81d/packages/hw-app-eth/src/Eth.ts#L468

                // we are interested in the first 65 bytes only
                guard data.count >= 65 else {
                    switch data.toHexString() {
                    case "6985": completion(nil, "The operation was canceled on the Ledger device.")
                    default: completion(nil, "Please check that Ethereum App is running on the Ledger device.")
                    }
                    // canceled on the device

                    return
                }
                let dataString = data.toHexString()
                let v = String(Int(dataString.substr(0, 2)!, radix: 16)! + 4, radix: 16)
                let rs = dataString.substr(2, 128)!
                completion(rs + v, nil)

            case .failure(_):
                completion(nil, "Please check that Ethereum App is running on the Ledger device.")
            }
        }
    }

    private func getAddressCommand(path: String,
                                   displayVerificationDialog: Bool = false,
                                   chainCode: Bool = false) -> Data {
        let paths = splitPath(path: path)

        var command = Data()
        var pathsData = Data()
        paths.forEach({ element in
                        let array = withUnsafeBytes(of: element.bigEndian, Array.init)
                        array.forEach { x in pathsData.append(x) } })

        command.append(UInt8(0xe0))
        command.append(UInt8(0x02))
        command.append(UInt8(displayVerificationDialog ? 0x01 : 0x00))
        command.append(UInt8(chainCode ? 0x01 : 0x00))

        command.append(UInt8(pathsData.count + 1))
        command.append(UInt8(paths.count))
        command.append(pathsData)

        return command
    }

    private func signMessageCommand(path: String, messageHash: String) -> Data {
        var command = Data()
        command.append(UInt8(0xe0))
        command.append(UInt8(0x08))
        command.append(UInt8(0x00))
        command.append(UInt8(0x00))

        let paths = splitPath(path: path)
        var pathsData = Data()
        paths.forEach({ element in
                        let array = withUnsafeBytes(of: element.bigEndian, Array.init)
                        array.forEach{ x in pathsData.append(x) } })
        var data = Data()
        data.append(UInt8(paths.count))
        data.append(pathsData)

        let messageData = Data(hex: messageHash)
        let array = withUnsafeBytes(of: Int32(messageData.count).bigEndian, Array.init)
        array.forEach{ x in data.append(x) }

        data.append(messageData)

        command.append(UInt8(data.count))
        command.append(data)

        // A command length should be 150 bytes long. Otherwise, we should split it into chunks.
        // As we sign hashes, we should be fine for now.
        guard command.count <= 150 else {
            preconditionFailure("Wrong length of message for signing")
        }

        return command
    }

    private func splitPath(path: String) -> [UInt32] {
        var result: [UInt32] = []
        let components = path.components(separatedBy: "/")
        components.forEach { component in
            var number = UInt32(0)
            var numberText = component
            if component.count > 1 && component.hasSuffix("\'") {
                number = 0x80000000
                numberText = String(component.dropLast(1))
            }

            if let index =  UInt32(numberText) {
                number = number + index
                result.append(number)
            }
        }

        return result
    }
}
