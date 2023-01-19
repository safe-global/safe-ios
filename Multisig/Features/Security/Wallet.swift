//
//  Wallet.swift
//  Multisig
//
//  Created by Mouaz on 1/11/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

class Wallet {
    static let shared = Wallet ()

    private init() { }

    func sign(_ transaction: Transaction, keyInfo: KeyInfo, completion: @escaping (Result<Signature, Error>) -> ()) {
        let hashToSign = Data(ethHex: transaction.safeTxHash.description)
        let data = transaction.encodeTransactionData()
        guard EthHasher.hash(data) == hashToSign else {
            completion (.failure(GSError.TransactionSigningError()))
            return
        }

        let hashString = HashString(transaction.safeTxHash.hash)
        sign(hash: hashString, keyInfo: keyInfo, completion: completion)
    }

    // This method is used to simplify the testing 
    func sign(_ transaction: Transaction, key: PrivateKey) throws -> Signature {
        let hashToSign = Data(ethHex: transaction.safeTxHash.description)
        let data = transaction.encodeTransactionData()
        guard EthHasher.hash(data) == hashToSign else {
            throw GSError.TransactionSigningError()
        }

        let hashString = HashString(transaction.safeTxHash.hash)
        return try key.sign(hash: hashString.hash)
    }

    func sign(hash: HashString, keyInfo: KeyInfo, completion: @escaping (Result<Signature, Error>) -> ()) {
        keyInfo.privateKey { result in
            do {
                guard let privateKey = try result.get() else {
                    completion(.failure(GSError.MissingPrivateKeyError()))
                    return
                }

                let signature = try privateKey.sign(hash: hash.hash)
                completion(.success(signature))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
}
