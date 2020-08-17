//
//  SCGTransactionSummaryListRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct SCGTransactionSummaryListRequest: JSONRequest {
    let safeAddress: String
    var httpMethod: String { "GET" }
    var urlPath: String {
        "/v1/safes/\(safeAddress)/transactions"
    }

    typealias ResponseType = SCGPage<SCGTransactionSummary>
}

extension SCGTransactionSummaryListRequest {
    init(_ address: Address) {
        safeAddress = address.checksummed
    }
}

extension SafeClientGatewayService {
    func transactionSummaryList(address: Address) throws -> SCGTransactionSummaryListRequest.ResponseType {
        try execute(request: SCGTransactionSummaryListRequest(address))
    }

    func transactionSummaryList(address: String) throws -> SCGTransactionSummaryListRequest.ResponseType {
        try execute(request: SCGTransactionSummaryListRequest(safeAddress: address))
    }
}
