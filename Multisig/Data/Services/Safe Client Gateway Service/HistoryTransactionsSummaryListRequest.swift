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
    let chainId: Int

    var httpMethod: String { "GET" }
    var urlPath: String {
        "/\(chainId)/v1/safes/\(safeAddress)/transactions/history"
    }

    var query: String? {
        return "timezone_offset=\(timezoneOffset)"
    }
    
    typealias ResponseType = Page<SCGModels.TransactionSummaryItem>
}

extension HistoryTransactionsSummaryListRequest {
    init(_ safe: Safe) {
        self.init(safeAddress: (try! Address(from: safe.address!)).checksummed,
                  chainId: safe.network!.id)
    }
}

extension SafeClientGatewayService {
    func asyncHistoryTransactionsSummaryList(
        safe: Safe,
        completion: @escaping (Result<HistoryTransactionsSummaryListRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {

        asyncExecute(request: HistoryTransactionsSummaryListRequest(safe), completion: completion)
    }

    func asyncHistoryTransactionsSummaryList(
        pageUri: String,
        completion: @escaping (Result<HistoryTransactionsSummaryListRequest.ResponseType, Error>) -> Void) throws -> URLSessionTask? {

        asyncExecute(request: try PagedRequest<SCGModels.TransactionSummaryItem>(pageUri), completion: completion)
    }
}
