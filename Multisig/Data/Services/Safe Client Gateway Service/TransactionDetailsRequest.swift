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
    let networkId: String
    
    var httpMethod: String { "GET" }
    var urlPath: String { "/v1/chains/\(networkId)/transactions/\(id)" }
    typealias ResponseType = SCGModels.TransactionDetails
}

extension TransactionDetailsRequest {
    init(safeTxHash: Data, networkId: String) {
        id = safeTxHash.toHexStringWithPrefix()
        self.networkId = networkId
    }
}

extension SafeClientGatewayService {
    @discardableResult
    func asyncTransactionDetails(
        id: String,
        networkId: String,
        completion: @escaping (Result<SCGModels.TransactionDetails, Error>) -> Void) -> URLSessionTask? {

        asyncExecute(request: TransactionDetailsRequest(id: id, networkId: networkId), completion: completion)
    }

    func asyncTransactionDetails(
        safeTxHash: Data,
        networkId: String,
        completion: @escaping (Result<SCGModels.TransactionDetails, Error>) -> Void) -> URLSessionTask? {

        asyncExecute(request: TransactionDetailsRequest(safeTxHash: safeTxHash, networkId: networkId),
                     completion: completion)
    }
}
