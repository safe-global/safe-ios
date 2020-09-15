//
//  TransactionSummaryListRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionSummaryListRequest: JSONRequest {
    let safeAddress: String
    var httpMethod: String { "GET" }
    var urlPath: String {
        "/v1/safes/\(safeAddress)/transactions"
    }
    typealias ResponseType =  Page<TransactionSummary>
}

extension TransactionSummaryListRequest {
    init(_ address: Address) {
        safeAddress = address.checksummed
    }
}

extension SafeClientGatewayService {
    func transactionSummaryList(address: Address) throws -> TransactionSummaryListRequest.ResponseType {
        try execute(request: TransactionSummaryListRequest(address))
    }

    func transactionSummaryList(address: String) throws -> TransactionSummaryListRequest.ResponseType {
        try execute(request: TransactionSummaryListRequest(safeAddress: address))
    }

    func transactionSummaryList(pageUri: String) throws -> TransactionSummaryListRequest.ResponseType {
        return try execute(request: PagedRequest<TransactionSummary>(pageUri))
    }
}
