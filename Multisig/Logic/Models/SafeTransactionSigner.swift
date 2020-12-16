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

    func sign(_ transaction: Transaction, by safeAddress: Address) throws -> Signer.Signature {
        let hashToSign = Data(ethHex: transaction.safeTxHash!.description)
        let data = transaction.encodeTransactionData(for: AddressString(safeAddress))
        guard EthHasher.hash(data) == hashToSign else {
            throw "Invalid safeTxHash, please check the transaction data"
        }

        return try Signer.sign(hash: hashToSign)        
    }

    class func numberOfKeysImported() -> Int {
        do {
            let pkData = try App.shared.keychainService.data(forKey: KeychainKey.ownerPrivateKey.rawValue)
            return pkData == nil ? 0 : 1
        } catch {
            App.shared.snackbar.show(error: GSError.error(description: "Failed to load keychain data", error: error))
            return 0
        }
    }

}
