//
//  RejectTransactionRequest.swift
//  Multisig
//
//  Created by Moaaz on 2/17/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct ProposeTransactionRequest: JSONRequest {
    let safe: AddressString
    let sender: AddressString
    let signature: String
    let transaction: Transaction
    let chainId: String
    
    enum CodingKeys: String, CodingKey {
        case sender
        case to
        case value
        case data
        case operation
        case safeTxGas
        case baseGas
        case gasPrice
        case gasToken
        case refundReceiver
        case nonce
        case safeTxHash
        case signature
    }

    var httpMethod: String { "POST" }
    var urlPath: String { "/v1/chains/\(chainId)/transactions/\(safe)/propose" }

    typealias ResponseType = SCGModels.TransactionDetails

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sender, forKey: .sender)
        try container.encode(transaction.to, forKey: .to)
        try container.encode(transaction.value, forKey: .value)
        try container.encode(transaction.data, forKey: .data)
        try container.encode(transaction.operation.rawValue, forKey: .operation)
        try container.encode(transaction.safeTxGas, forKey: .safeTxGas)
        try container.encode(transaction.baseGas, forKey: .baseGas)
        try container.encode(transaction.gasPrice, forKey: .gasPrice)
        try container.encode(transaction.gasToken, forKey: .gasToken)
        try container.encode(transaction.refundReceiver, forKey: .refundReceiver)
        try container.encode(transaction.nonce, forKey: .nonce)
        try container.encode(transaction.safeTxHash, forKey: .safeTxHash)
        try container.encode(signature, forKey: .signature)
    }
}

extension SafeClientGatewayService {
    @discardableResult
    func asyncProposeTransaction(
        transaction: Transaction,
        sender: AddressString,
        signature: String,
        chainId: String,
        completion: @escaping (Result<ProposeTransactionRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {

        return asyncExecute(request: ProposeTransactionRequest(safe: transaction.safe!,
                                                               sender: sender,
                                                               signature: signature,
                                                               transaction: transaction,
                                                               chainId: chainId),
                            completion: completion)
    }

    @discardableResult
    func proposeTransaction(transaction: Transaction, sender: AddressString, signature: String, chainId: String) throws -> SCGModels.TransactionDetails? {
        let request = ProposeTransactionRequest(safe: transaction.safe!,
                                                sender: sender,
                                                signature: signature,
                                                transaction: transaction,
                                                chainId: chainId)
        return try execute(request: request)
    }
}
