//
//  SignTransactionRequest.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 17.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3

#warning("Figure out how to handle the case if private key can not be extracted from the keychain")
struct SignTransactionRequest: JSONRequest {
    let safe: String

    let to: String
    let value: String
    let data: String
    let operation: Int
    let safeTxGas: String
    let baseGas: String
    let gasPrice: String
    let gasToken: String
    let refundReceiver: String
    let nonce: String
    let contractTransactionHash: String
    let sender: String
    let signature: String?

    enum CodingKeys: String, CodingKey {
        case sender, to, nonce, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver,
             contractTransactionHash, data, operation, value, signature
    }

    enum RequestError: String, Error {
        case couldNotVerifySafeTxHash = "Could not verify provided safeTxHash"
    }

    init(transaction: Transaction, safeAddress: Address) throws {
        safe = safeAddress.checksummed
        to = transaction.to.description
        value = transaction.value.description
        data = transaction.data.description
        operation = transaction.operation.rawValue
        safeTxGas = transaction.safeTxGas.description
        baseGas = transaction.baseGas.description
        gasPrice = transaction.gasPrice.description
        gasToken = transaction.gasToken.description
        refundReceiver = transaction.refundReceiver.description
        nonce = transaction.nonce.description
        contractTransactionHash = transaction.safeTxHash!.description

        let hashToSign = Data(ethHex: contractTransactionHash)
        let data = transaction.encodeTransactionData(for: AddressString(safeAddress))
        guard EthHasher.hash(data) == hashToSign else {
            // log error in the crashlytics
            throw RequestError.couldNotVerifySafeTxHash
        }

        guard let pkData = try? App.shared.keychainService.data(forKey: KeychainKey.ownerPrivateKey.rawValue),
              let privateKey = try? EthereumPrivateKey(pkData.bytes),
              let signature = try? privateKey.sign(hash: hashToSign.bytes) else {
            sender = ""
            self.signature = ""
            return
        }
        sender = privateKey.address.hex(eip55: true)

        let v = String(signature.v + 27, radix: 16)
        self.signature = "\(signature.r.toHexString())\(signature.s.toHexString())\(v)"
    }

    var httpMethod: String { return "POST" }
    var urlPath: String { return "/api/v1/safes/\(safe)/transactions/" }

    typealias ResponseType = Response

    struct Response: Decodable {}
}

extension SafeTransactionService {
    func sign(transaction: Transaction, safeAddress: Address) throws -> SignTransactionRequest.Response {
        let request = try SignTransactionRequest(transaction: transaction, safeAddress: safeAddress)
        return try execute(request: request)
    }
}
