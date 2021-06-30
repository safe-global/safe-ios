//
//  QueuedTransactionsSummaryRequest.swift
//  Multisig
//
//  Created by Moaaz on 12/9/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct QueuedTransactionsSummaryListRequest: JSONRequest {
    let safeAddress: String
    let chainId: Int
    
    let timezoneOffset = TimeZone.currentOffest()
    var httpMethod: String { "GET" }
    var urlPath: String {
        "/\(chainId)/v1/safes/\(safeAddress)/transactions/queued"
    }

    var query: String? {
        return "timezone_offset=\(timezoneOffset)"
    }

    typealias ResponseType = Page<SCGModels.TransactionSummaryItem>
}

extension QueuedTransactionsSummaryListRequest {
    init(_ safe: Safe) {
        self.init(safeAddress: (try! Address(from: safe.address!)).checksummed,
                  chainId: safe.network!.id)
    }
}

extension SafeClientGatewayService {
    func asyncQueuedTransactionsSummaryList(
        safe: Safe,
        completion: @escaping (Result<QueuedTransactionsSummaryListRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {

        asyncExecute(request: QueuedTransactionsSummaryListRequest(safe), completion: completion)
    }

    func asyncQueuedTransactionsSummaryList(
        pageUri: String,
        completion: @escaping (Result<QueuedTransactionsSummaryListRequest.ResponseType, Error>) -> Void) throws -> URLSessionTask? {

        asyncExecute(request: try PagedRequest<SCGModels.TransactionSummaryItem>(pageUri), completion: completion)
    }
}
