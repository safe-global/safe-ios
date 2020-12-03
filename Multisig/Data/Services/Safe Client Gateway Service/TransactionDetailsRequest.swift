//
//  SCGTransactionDetailsRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionDetailsRequest: JSONRequest {
    private let id: String
    var httpMethod: String { "GET" }
    var urlPath: String {
        "/v1/transactions/\(id)"
    }
    typealias ResponseType = TransactionDetails
}

extension TransactionDetailsRequest {
    init(transactionID: TransactionID) {
        id = transactionID.value
    }

    init(safeTxHash: Data) {
        id = safeTxHash.toHexStringWithPrefix()
    }
}

extension SafeClientGatewayService {
    func transactionDetails(id: TransactionID) throws -> TransactionDetailsRequest.ResponseType {
        try execute(request: TransactionDetailsRequest(transactionID: id))
    }

    func transactionDetails(safeTxHash: Data) throws -> TransactionDetailsRequest.ResponseType {
        try execute(request: TransactionDetailsRequest(safeTxHash: safeTxHash))
    }

    func asyncTransactionDetails(id: TransactionID, completion: @escaping (Result<TransactionDetails, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: TransactionDetailsRequest(transactionID: id), completion: completion)
    }

    func asyncTransactionDetails(safeTxHash: Data, completion: @escaping (Result<TransactionDetails, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: TransactionDetailsRequest(safeTxHash: safeTxHash), completion: completion)
    }
}

struct TransactionDetailsRequestV2:  JSONRequest {
    var id: String
    var httpMethod: String { "GET" }
    var urlPath: String { "/v1/transactions/\(id)" }
    typealias ResponseType = SCG.TransactionDetails
}

extension TransactionDetailsRequestV2  {
    init(safeTxHash: Data) {
        id = safeTxHash.toHexStringWithPrefix()
    }
}

extension SafeClientGatewayService {
    func asyncTransactionDetailsV2(id: String, completion: @escaping (Result<SCG.TransactionDetails, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: TransactionDetailsRequestV2(id: id), completion: completion)
    }

    func asyncTransactionDetailsV2(safeTxHash: Data, completion: @escaping (Result<SCG.TransactionDetails, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: TransactionDetailsRequestV2(safeTxHash: safeTxHash), completion: completion)
    }
}
