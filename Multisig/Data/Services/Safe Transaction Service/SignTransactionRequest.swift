//
//  SignTransactionRequest.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 17.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

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
        let signature = try SafeTransactionSigner().sign(transaction, by: safeAddress)
        self.sender = signature.signer
        self.signature = signature.value
    }

    var httpMethod: String { return "POST" }
    var urlPath: String { return "/api/v1/safes/\(safe)/transactions/" }

    typealias ResponseType = Response

    struct Response: Decodable {}
}

extension SafeTransactionService {
    @discardableResult
    func sign(transaction: Transaction, safeAddress: Address) throws -> SignTransactionRequest.Response {
        let request = try SignTransactionRequest(transaction: transaction, safeAddress: safeAddress)
        return try execute(request: request)
    }
}
