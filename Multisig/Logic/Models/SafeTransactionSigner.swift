//
//  TransactionSigner.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 23.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3

class SafeTransactionSigner {

    struct Signature {
        var value: String
        var sender: String
    }

    func sign(_ transaction: Transaction, by safeAddress: Address) throws -> Signature {
        let hashToSign = Data(ethHex: transaction.safeTxHash!.description)
        let data = transaction.encodeTransactionData(for: AddressString(safeAddress))
        guard EthHasher.hash(data) == hashToSign else {
            throw "Invalid safeTxHash, please check the transaction data"
        }
        guard let pkData = try App.shared.keychainService.data(forKey: KeychainKey.ownerPrivateKey.rawValue) else {
            throw "Private key not found"
        }
        let privateKey = try EthereumPrivateKey(pkData.bytes)
        let eoaSignature = try privateKey.sign(hash: hashToSign.bytes)
        let sender = privateKey.address.hex(eip55: true)
        let v = String(eoaSignature.v + 27, radix: 16)
        let safeSignature = "\(eoaSignature.r.toHexString())\(eoaSignature.s.toHexString())\(v)"
        return Signature(value: safeSignature, sender: sender)
    }

    class func numberOfKeysImported() -> Int {
        do {
            let pkData = try App.shared.keychainService.data(forKey: KeychainKey.ownerPrivateKey.rawValue)
            return [pkData].compactMap { $0 }.count
        } catch {
            LogService.shared.error("Failure to get the key from keychain: \(error)")
            return 0
        }
    }

}
