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
        // Check that transaction hash is calculated properly
        let hashToSign = Data(ethHex: transaction.safeTxHash!.description)
        let data = transaction.encodeTransactionData()
        guard EthHasher.hash(data) == hashToSign else {
            throw GSError.TransactionSigningError()
        }

        guard let key = try keyInfo.privateKey() else {
            throw GSError.MissingPrivateKeyError()
        }

        return try key.sign(hash: transaction.safeTxHash!.hash)
    }
}
