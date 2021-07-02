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
    let timezoneOffset = TimeZone.currentOffest()
    let networkId: Int

    var httpMethod: String { "GET" }
    var urlPath: String {
        "/\(networkId)/v1/safes/\(safeAddress)/transactions/history"
    }

    var query: String? {
        return "timezone_offset=\(timezoneOffset)"
    }
    
    typealias ResponseType = Page<SCGModels.TransactionSummaryItem>
}

extension HistoryTransactionsSummaryListRequest {
    init(_ safeAddress: Address, networkId: Int) {
        self.init(safeAddress: safeAddress.checksummed, networkId: networkId)
    }
}

extension SafeClientGatewayService {
    func asyncHistoryTransactionsSummaryList(
        safeAddress: Address,
        networkId: Int,
        completion: @escaping (Result<HistoryTransactionsSummaryListRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {

        asyncExecute(request: HistoryTransactionsSummaryListRequest(safeAddress, networkId: networkId),
                     completion: completion)
    }

    func asyncHistoryTransactionsSummaryList(
        pageUri: String,
        completion: @escaping (Result<HistoryTransactionsSummaryListRequest.ResponseType, Error>) -> Void) throws -> URLSessionTask? {

        asyncExecute(request: try PagedRequest<SCGModels.TransactionSummaryItem>(pageUri), completion: completion)
    }
}
