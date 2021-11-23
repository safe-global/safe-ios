//
//  LedgerCommandController.swift
//  Multisig
//
//  Created by Moaaz on 7/28/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class LedgerController {
    let bluetoothController: BaseBluetoothController

    enum LedgerResponseCode: String {
        case canceled = "6985"
    }

    init(bluetoothController: BaseBluetoothController) {
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
                guard data.count >= 107,
                      data[0] == 65, // public key length
                      data[66] == 40 // address length
                else {
                    completion(nil)
                    return
                }
                
                let addressData = data[(1 + 65 + 1)..<(1 + 65 + 1 + 40)]

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

    func sign(messageHash: String, deviceId: UUID, path: String, completion: @escaping SignatureCompletion) {
        guard let device = bluetoothController.deviceFor(deviceId: deviceId) else {
            completion(nil, "Device not found")
            return
        }
        let command = signMessageCommand(path: path, messageHash: messageHash)

        // We don't use [weak self] with private methods not to capture LedgerController in a caller
        bluetoothController.sendCommand(device: device, command: command) { result in
            switch result {
            case .success(let data):
                // https://github.com/LedgerHQ/ledgerjs/blob/c329fe63f6f640a9f4c2f200a788fa845547e81d/packages/hw-app-eth/src/Eth.ts#L468

                // we are interested in the first 65 bytes only
                guard data.count >= 65 else {
                    switch data.toHexString() {
                    case LedgerResponseCode.canceled.rawValue:
                        completion(nil, "The operation was canceled on the Ledger device.")
                    default:
                        completion(nil, "Please check that Ethereum App is running on the Ledger device.")
                    }
                    // canceled on the device

                    return
                }

                // Ledger is signing with eth_sign (similar to https://docs.ethers.io/v5/api/signer/#Signer-signMessage)
                // That means that when we pass the "messageHash" to the ledger, it signs a hash of the message
                // with a prefix.
                //
                // Now, Ethereum signatures has to have 'v' equal to 27 or 28.
                // However, Gnosis Safe contract expects a modified 'v' parameter if the signature was actually
                // produced by the eth_sign method. It expects that the 'v' part be increased by 4, in this case
                // the 'v' would be 31 or 32. This way contract can recover signer address with eth_sign.
                // See more: https://github.com/gnosis/safe-contracts/blob/8c84fb3a1accaeffab24fd53e89ec626158ab818/contracts/GnosisSafe.sol#L292

                // Next we're going to adjust the 'v' according to Gnosis Safe 'v' expectations and
                // also change the signature layout from 'vrs' to 'rsv' which is expected by the contracts.

                // The 'data' we get from Ledger has signature at first 65 bytes.
                // The layout is: <v: 1 byte><r: 32 bytes><s: 32 bytes>
                let v = data[0]
                let r = Data(Array(data[1..<32]))
                let s = Data(Array(data[32..<65]))

                let gnosisSafeSignature = r + s + Data([v + 4])

                completion(gnosisSafeSignature.toHexString(), nil)

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
