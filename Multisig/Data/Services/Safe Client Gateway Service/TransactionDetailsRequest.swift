//
//  SCGTransactionDetailsRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionDetailsRequest: JSONRequest {
    var id: String
    var httpMethod: String { "GET" }
    var urlPath: String { "/v1/transactions/\(id)" }
    typealias ResponseType = SCGModels.TransactionDetails
}

extension TransactionDetailsRequest {
    init(safeTxHash: Data) {
        id = safeTxHash.toHexStringWithPrefix()
    }
}

extension SafeClientGatewayService {
    func asyncTransactionDetails(id: String, completion: @escaping (Result<SCGModels.TransactionDetails, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: TransactionDetailsRequest(id: id), completion: completion)
    }

    func asyncTransactionDetails(safeTxHash: Data, completion: @escaping (Result<SCGModels.TransactionDetails, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: TransactionDetailsRequest(safeTxHash: safeTxHash), completion: completion)
    }
}
