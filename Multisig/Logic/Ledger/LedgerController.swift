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

    func getAddress(deviceId: UUID, completion: @escaping (Address?) -> Void) {
        guard let device = bluetoothController.deviceFor(deviceId: deviceId) else {
            completion(nil)
            return
        }
        let command = getAddressCommand(path: /*"44'/60'/0'/0'/0"*/ HDNode.defaultPathMetamask)
        bluetoothController.sendCommand(device: device, command: command) { data in

            print("Parsed response data: \(data.toHexString())")
            completion(nil)
        }
    }

    private func getAddressCommand(path: String,
                                   displayVerificationDialog: Bool = true,
                                   chainCode: Bool = false) -> Data {
        let paths = splitPath(path: path)

        var command = Data()
        var pathsData = Data()
        paths.forEach({ element in
                        let array = withUnsafeBytes(of: element.bigEndian, Array.init)
                        array.forEach{ x in pathsData.append(x) } })

        command.append(UInt8(0xe0))
        command.append(UInt8(0x02))
        command.append(UInt8(displayVerificationDialog ? 0x01 : 0x00))
        command.append(UInt8(chainCode ? 0x01 : 0x00))

        command.append(UInt8(pathsData.count + 1))
        command.append(UInt8(paths.count))
        command.append(pathsData)

        return command
    }

    private func signMessage(path: String, message: String) throws -> Data {
        let paths = splitPath(path: path)
        var command = Data()
        var pathsData = Data()
        paths.forEach({ element in
                        let array = withUnsafeBytes(of: element.bigEndian, Array.init)
                        array.forEach{ x in pathsData.append(x) } })

        command.append(UInt8(0xe0))
        command.append(UInt8(0x08))
        command.append(UInt8(0x00))
        command.append(UInt8(0x00))

        var data = Data()
        data.append(UInt8(paths.count))
        data.append(pathsData)
        let messageData = message.data(using: .ascii) ?? Data()

        let array = withUnsafeBytes(of: Int32(messageData.count).bigEndian, Array.init)
        array.forEach{ x in data.append(x) }

        data.append(messageData)

        command.append(UInt8(data.count))
        command.append(data)

        // Command length should be 150 bytes length otherwise we should split it into chuncks
        guard command.count <= 150 else {
            throw GSError.LedgerCommandError()
        }

        return command
    }

    private func parseGetAddress(data: Data) throws -> (publicKey: Data, address: String) {
        guard data.count > 5 else {
            throw GSError.LedgerResponseError()
        }

        let publicKeyLength = Int(data[5])

        guard data.count > 5 + publicKeyLength else {
            throw GSError.LedgerResponseError()
        }

        let addressLength = Int(data[6 + publicKeyLength])

        guard data.count == 2 + publicKeyLength + addressLength else {
            throw GSError.LedgerResponseError()
        }

        let publicKey = data[6..<publicKeyLength]
        let address = data[6 + publicKeyLength + 1..<6 + publicKeyLength + 1 + addressLength]

        return (publicKey, String(data: address, encoding: .ascii)!)
    }

    private func parseSignMessage(data: Data) throws -> (v: Data, r: Data, s: Data) {
        guard data.count == 65 else {
            throw GSError.LedgerResponseError()
        }

        let v = data[0..<1]
        let r = data[1...32]
        let s = data[33...65]

        return (v, r, s)
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
