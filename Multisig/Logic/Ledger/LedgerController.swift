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
                let r = Data(Array(data[1..<1 + 32]))
                let s = Data(Array(data[1 + 32..<1 + 32 + 32]))

                let gnosisSafeSignature = r + s + Data([v + 4])

                completion(gnosisSafeSignature.toHexString(), nil)

            case .failure(_):
                completion(nil, "Please check that Ethereum App is running on the Ledger device.")
            }
        }
    }

    // sign eth transaction
    func sign(chainId: Int, isLegacy: Bool, rawTransaction: Data, deviceId: UUID, path: String, completion: @escaping (Result<(v: UInt8, r: Data, s: Data), Error>) -> Void) {
        /*
         This command signs an Ethereum transaction after having the user validate the following parameters

         Gas price

         Gas limit

         Recipient address

         Value

         The input data is the RLP encoded transaction (as per https://github.com/ethereum/pyethereum/blob/develop/ethereum/transactions.py#L22), without v/r/s present, streamed to the device in 255 bytes maximum data chunks.
         */

        // NOTE: the js packages/hw-app-eth/src/Eth.ts is using 150 byte chunks


        // APDU Command Parameters

        // CLA = E0 (1 byte)
        // INS = 04 (1 byte)
        // P1 = (1 byte)
            // 00: first transaction data block
            // 80: subsequent transaction data block
        // P2 = 00 (1 byte)
        // Lc = var Encodes the number (Nc) of bytes of command data to follow
            // 0 denotes Nc=0
            // 1 byte, 1...255 denotes Nc with the same length
            // 3 bytes, 1st=0, Denotes Nc in range 1 to 65 535 (all 3 non-zero)
        // Command data (Nc bytes): Nc bytes of data
            // 1st transaction data block
                // Number of Bip32 derivations to perfrom (max 10): 1 byte
                // First derivation index (big endian): 4 bytes
                // ...                               : 4 bytes
                // Last derivation index (big endian): 4 bytes
                // RLP transaction chunk (variable)
                    // NOTE: if chain_id is more than 4 bytes in rlp-encoding
                        // i.e. chain_id.bitWidth is > 32
                        // then it'll be truncated...

            // other data transaction block
                // RLP tansaction chunk: variable


        // Le = Encodes the maximum number (Ne) of response bytes expected
            // 0 bytes denotes Ne = 0
            // 1 byte in range 1...255 denotes that value of Ne, 0 denotes Ne=256
            // 2 bytes (if extended Lc was present in the command) in the range 1 to 65 535 denotes Ne of that value, or two zero bytes denotes 65 536
            // 3 bytes (if Lc was not present in the command), the first of which must be 0, denote Ne in the same way as two-byte Le


        // Response APDU
        // Data = Nr bytes 9at most Ne): response data
            // v: 1 byte
                    // chain_id here is 4-byte truncated (uint32)
                // if (chain_id * 2 + 35) + 1 > 255:
                    // ecc_parity = result[0] - ((chain_id * 2 + 35) % 256)
                    // v = (chain_id*2 + 35) + ecc_parity
            // r: 32 bytes
            // s: 32 bytes
        // SW1 (1)
        // SW2 (1): response trailer, command processing status
        //        i.e. 90 00 = success


        // all data = (encode paths + raw tx data).split into max 255-byte length
        // first chunk's P1 = 00
        //  else P1 = 80
        // Lc = chunk's size (1 byte) (guaranteed to be in range 1 to 255)
        // Le = 0 bytes of response in pre-last chunks | 65 (1 byte) - 65 bytes of response in last chunk


        // send - receive until the last chunk is sent.

        // prepare the data to send
            // convert derivation path into derviation indices - maximum is 10
        let bip32DerivationIndices = splitPath(path: path).prefix(10)

            // number of bip32 derivations (number of derivation path components) as 1 byte
        let numberOfDerivations: UInt8 = UInt8(bip32DerivationIndices.count)

            // each derivation path component as 4-byte big endian
        let indexesBytes: [UInt8] = bip32DerivationIndices
            .map(\.bigEndian)
            .flatMap { withUnsafeBytes(of: $0, Array.init) }


        let data = Data([numberOfDerivations] + indexesBytes) + rawTransaction

        let maxChunkSize = 150
        let chunks = stride(from: 0, to: data.count, by: maxChunkSize).map { offset -> Data in
            data[offset..<min(data.count, offset + maxChunkSize)]
        }

        // convert to adpus
        // CLA = E0 (1 byte)
        let cla: UInt8 = 0xE0

        // INS = 04 (1 byte)
        let ins: UInt8 = 0x04

        // P1 = (1 byte)
            // 00: first transaction data block
        let p1_chunk0: UInt8 = 0x00

            // 80: subsequent transaction data block
        let p1_chunkOther: UInt8 = 0x80

        // P2 = 00 (1 byte)
        let p2: UInt8 = 0x00

        // Lc = var Encodes the number (Nc) of bytes of command data to follow
            // 0 denotes Nc=0
            // 1 byte, 1...255 denotes Nc with the same length
            // 3 bytes, 1st=0, Denotes Nc in range 1 to 65 535 (all 3 non-zero)
        // since all chunks are maximum 255 bytes, then it will fit into 1 byte
        var lc: UInt8 = 0

        // Command data (Nc bytes): Nc bytes of data
            // this will be each chunk.

        let apduCommands = chunks.enumerated().map { index, chunk -> Data in
            let p1: UInt8 = index == 0 ? p1_chunk0 : p1_chunkOther
            lc = UInt8(chunk.count)
            let result = Data([cla, ins, p1, p2, lc]) + chunk
            return result
        }

        // now send each command one after another checking that each was successful.
        // the last command should get the response.
        guard let device = bluetoothController.deviceFor(deviceId: deviceId) else {
            let error = LedgerControllerError(code: -2, message: "Device not found")
            completion(.failure(error))
            return
        }

//        bluetoothController.sendCommand(device: device, commands: apduCommands) { result in
        send(commands: apduCommands, device: device) { result in
            switch result {
            case .failure(let error):
                LogService.shared.error("Ledger error: \(error)")
                let userError = LedgerControllerError(code: -3, message: "Please check that Ethereum App is running on the Ledger device.")
                dispatchOnMainThread(completion(.failure(userError)))

            case .success(let data):

                // we are interested in the first 65 bytes only
                guard data.count >= 65 else {
                    let error: Error
                    switch data.toHexString() {
                    case LedgerResponseCode.canceled.rawValue:
                        error = LedgerControllerError(code: -4, message: "The operation was canceled on the Ledger device.")
                    default:
                        error = LedgerControllerError(code: -5, message: "Please check that Ethereum app is running. Device error \(data.toHexStringWithPrefix())")
                    }
                    completion(.failure(error))
                    return
                }

                var v = data[0]
                let r = Data(Array(data[1..<1 + 32]))
                assert(r.count == 32)
                let s = Data(Array(data[1 + 32..<1 + 32 + 32]))
                assert(s.count == 32)

                // for legacy transactions
                // we need to recover the 'v' in case the chain_id would lead to overflow 1 byte when rlp-encoded:
                let eip155maxV = chainId * 2 + 35 + 1
                if isLegacy && eip155maxV > 255 {
                    v = data[0] - UInt8((chainId * 2 + 35) % 256)
                }
                assert(v == 0 || v == 1)

                completion(.success((v, r, s)))
            }
        }
    }

    func send(at index: Int = 0, commands: [Data], device: BaseBluetoothDevice, completion: @escaping (Result<Data, Error>) -> Void) {
        if commands.isEmpty {
            let error = LedgerControllerError(code: -1, message: "Nothing to send to the Ledger device")
            completion(.failure(error))
            return
        }

        let command = commands[index]
        bluetoothController.sendCommand(device: device, command: command, index: UInt16(index)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                // once something failed, everything failed.
                completion(.failure(error))

            case .success(let data):
                // ignore if was not the last command
                if index == commands.count - 1 {
                    completion(.success(data))
                } else {
                    // recursively send next command
                    self.send(at: index + 1, commands: commands, device: device, completion: completion)
                }
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

        let messageData: Data = Data(hex: messageHash)
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

struct LedgerControllerError: LocalizedError {
    let code: Int
    let message: String

    var errorDescription: String? { "\(message) (Error \(code))"}
}
