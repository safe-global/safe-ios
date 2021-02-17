//
//  RejectTransactionRequest.swift
//  Multisig
//
//  Created by Moaaz on 2/17/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct ProposeTransactionRequest: JSONRequest {
    let safeAddress: String
    let to: String
    let value: String
    let data: String
    let nonce: String
    let operation: String
    let safeTxGas: String
    let baseGas: String
    let gasPrice: String
    let gasToken: String
    let refundReceiver: String
    let safeTxHash: String
    let sender: String
    let signature: String
    var httpMethod: String { "POST" }
    var urlPath: String { "/v1/transactions/\(safeAddress)/propose" }
    typealias ResponseType = SCGModels.TransactionDetails

    enum CodingKeys: String, CodingKey {
        case to
        case value
        case data
        case nonce
        case operation
        case safeTxGas
        case baseGas
        case gasPrice
        case gasToken
        case refundReceiver
        case safeTxHash
        case sender
        case signature
    }

    init(transaction: Transaction, safeAddress: String, signature: String) {
        self.safeAddress = safeAddress
        to = transaction.to.description
        value = transaction.value.description
        data = transaction.data.description
        nonce = transaction.nonce.description
        operation = "\(transaction.operation.rawValue)"
        safeTxGas = transaction.safeTxGas.description
        baseGas = transaction.baseGas.description
        gasPrice = transaction.gasPrice.description
        gasToken = transaction.gasToken.description
        refundReceiver = transaction.refundReceiver.description
        safeTxHash = transaction.safeTxHash?.description ?? ""
        sender = safeAddress
        self.signature = signature
    }
}

extension SafeClientGatewayService {
    func propose(transaction: Transaction, safeAddress: String, signature: String, completion: @escaping (Result<SCGModels.TransactionDetails, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: ProposeTransactionRequest(transaction: transaction, safeAddress: safeAddress, signature: signature), completion: completion)
    }
}
