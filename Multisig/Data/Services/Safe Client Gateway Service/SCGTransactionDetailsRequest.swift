//
//  SCGTransactionDetailsRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct SCGTransactionDetailsRequest: JSONRequest {
    private let id: String
    var httpMethod: String { "GET" }
    var urlPath: String {
        "/v1/transactions/\(id)"
    }
    typealias ResponseType = SCGTransactionDetails
}

extension SCGTransactionDetailsRequest {
    init(transactionID: SCGTransactionID) {
        id = transactionID.value
    }

    init(safeTxHash: Data) {
        id = safeTxHash.toHexStringWithPrefix()
    }
}

extension SafeClientGatewayService {
    func transactionDetails(id: SCGTransactionID) throws -> SCGTransactionDetailsRequest.ResponseType {
        try execute(request: SCGTransactionDetailsRequest(transactionID: id))
    }

    func transactionDetails(safeTxHash: Data) throws -> SCGTransactionDetailsRequest.ResponseType {
        try execute(request: SCGTransactionDetailsRequest(safeTxHash: safeTxHash))
    }
}
