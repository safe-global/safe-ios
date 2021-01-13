//
//  HistoryTransactionsSummaryListRequest.swift
//  Multisig
//
//  Created by Moaaz on 12/9/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct HistoryTransactionsSummaryListRequest: JSONRequest {
    let safeAddress: String
    var httpMethod: String { "GET" }
    var urlPath: String {
        "/v1/safes/\(safeAddress)/transactions/history"
    }
    typealias ResponseType = Page<SCGModels.TransactionSummaryItem>
}

extension HistoryTransactionsSummaryListRequest {
    init(_ address: Address) {
        safeAddress = address.checksummed
    }
}

extension SafeClientGatewayService {
    func asyncHistoryTransactionsSummaryList(address: Address, completion: @escaping (Result<HistoryTransactionsSummaryListRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: HistoryTransactionsSummaryListRequest(address), completion: completion)
    }

    func asyncHistoryTransactionsSummaryList(pageUri: String, completion: @escaping (Result<HistoryTransactionsSummaryListRequest.ResponseType, Error>) -> Void) throws -> URLSessionTask? {
        asyncExecute(request: try PagedRequest<SCGModels.TransactionSummaryItem>(pageUri), completion: completion)
    }
}
