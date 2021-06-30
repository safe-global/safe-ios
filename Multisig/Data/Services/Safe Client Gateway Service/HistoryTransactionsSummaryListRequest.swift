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
    init(_ address: Address, chainId: Int) {
        safeAddress = address.checksummed
        self.chainId = chainId
    }
}

extension SafeClientGatewayService {
    func asyncHistoryTransactionsSummaryList(address: Address, completion: @escaping (Result<HistoryTransactionsSummaryListRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: HistoryTransactionsSummaryListRequest(address, chainId: chainId), completion: completion)
    }

    func asyncHistoryTransactionsSummaryList(pageUri: String, completion: @escaping (Result<HistoryTransactionsSummaryListRequest.ResponseType, Error>) -> Void) throws -> URLSessionTask? {
        asyncExecute(request: try PagedRequest<SCGModels.TransactionSummaryItem>(pageUri), completion: completion)
    }
}
