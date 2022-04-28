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
    func sign(_ transaction: Transaction, keyInfo: KeyInfo) throws -> Signature {
        guard let key = try keyInfo.privateKey() else {
            throw GSError.MissingPrivateKeyError()
        }
        return try sign(transaction, key: key)
    }

    func sign(_ transaction: Transaction, key: PrivateKey) throws -> Signature {
        let hashToSign = Data(ethHex: transaction.safeTxHash.description)
        let data = transaction.encodeTransactionData()
        guard EthHasher.hash(data) == hashToSign else {
            throw GSError.TransactionSigningError()
        }

        let hashString = HashString(transaction.safeTxHash.hash)
        return try key.sign(hash: hashString.hash)
    }

    func sign(hash: HashString, keyInfo: KeyInfo) throws -> Signature {
        guard let key = try keyInfo.privateKey() else {
            throw GSError.MissingPrivateKeyError()
        }

        return try key.sign(hash: hash.hash)
    }
}
