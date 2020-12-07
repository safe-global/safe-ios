//
//  ConfirmTransactionRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 23.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct ConfirmTransactionRequest: JSONRequest {
    var safeTxHash: String
    var signedSafeTxHash: String
    var httpMethod: String { "POST" }
    var urlPath: String { "/v1/transactions/\(safeTxHash)/confirmations" }
    typealias ResponseType = TransactionDetails

    enum CodingKeys: String, CodingKey {
        case signedSafeTxHash
    }
}

extension SafeClientGatewayService {
    func confirm(safeTxHash: String, with signature: String) throws -> TransactionDetails {
        try execute(request: ConfirmTransactionRequest(safeTxHash: safeTxHash, signedSafeTxHash: signature))
    }
}

struct ConfirmTransactionRequestV2: JSONRequest {
    var safeTxHash: String
    var signedSafeTxHash: String
    var httpMethod: String { "POST" }
    var urlPath: String { "/v1/transactions/\(safeTxHash)/confirmations" }
    typealias ResponseType = SCG.TransactionDetails

    enum CodingKeys: String, CodingKey {
        case signedSafeTxHash
    }
}

extension SafeClientGatewayService {
    func asyncConfirm(safeTxHash: String, with signature: String, completion: @escaping (Result<SCG.TransactionDetails, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: ConfirmTransactionRequestV2(safeTxHash: safeTxHash, signedSafeTxHash: signature), completion: completion)
    }
}
