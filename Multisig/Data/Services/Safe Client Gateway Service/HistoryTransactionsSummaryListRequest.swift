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
    typealias ResponseType = Page<TransactionSummaryItemWrapper>
}

extension HistoryTransactionsSummaryListRequest {
    init(_ address: Address) {
        safeAddress = address.checksummed
    }
}

extension SafeClientGatewayService {
    func historyTransactionsSummaryList(address: Address) throws -> HistoryTransactionsSummaryListRequest.ResponseType {
        try execute(request: HistoryTransactionsSummaryListRequest(address))
    }

    func historyTransactionsSummaryList(address: String) throws -> HistoryTransactionsSummaryListRequest.ResponseType {
        try execute(request: HistoryTransactionsSummaryListRequest(safeAddress: address))
    }

    func historyTransactionsSummaryList(pageUri: String) throws -> HistoryTransactionsSummaryListRequest.ResponseType {
        return try execute(request: PagedRequest<TransactionSummaryItemWrapper>(pageUri))
    }

    func asyncHistoryTransactionsSummaryList(address: Address, completion: @escaping (Result<HistoryTransactionsSummaryListRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: HistoryTransactionsSummaryListRequest(address), completion: completion)
    }

    func asyncHistoryTransactionsSummaryList(pageUri: String, completion: @escaping (Result<HistoryTransactionsSummaryListRequest.ResponseType, Error>) -> Void) throws -> URLSessionTask? {
        asyncExecute(request: try PagedRequest<TransactionSummaryItemWrapper>(pageUri), completion: completion)
    }
}
