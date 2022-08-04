//
//  TransactionPreviewRequest.swift
//  Multisig
//
//  Created by Moaaz on 7/5/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionPreviewRequest: JSONRequest {
    let safe: AddressString
    let sender: AddressString
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
    }

    var httpMethod: String { "POST" }
    var urlPath: String { "/v1/chains/\(chainId)/transactions/\(safe)/preview" }

    typealias ResponseType = SCGModels.TrasactionPreview

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
    }
}

extension SafeClientGatewayService {
    @discardableResult
    func asyncPreviewTransaction(
        transaction: Transaction,
        sender: AddressString,
        chainId: String,
        completion: @escaping (Result<TransactionPreviewRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {

        asyncExecute(request: TransactionPreviewRequest(safe: transaction.safe!,
                                                               sender: sender,
                                                               transaction: transaction,
                                                               chainId: chainId),
                            completion: completion)
    }

    @discardableResult
    func previewTransaction(transaction: Transaction, sender: AddressString, chainId: String) throws -> SCGModels.TrasactionPreview? {
        let request = TransactionPreviewRequest(safe: transaction.safe!,
                sender: sender,
                transaction: transaction,
                chainId: chainId)
        return try execute(request: request)
    }
}
