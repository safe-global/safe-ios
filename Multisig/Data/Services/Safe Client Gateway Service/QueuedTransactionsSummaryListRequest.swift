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
    let timezoneOffset = TimeZone.currentOffest()
    var httpMethod: String { "GET" }
    var urlPath: String {
        "/v1/safes/\(safeAddress)/transactions/queued"
    }

    var query: String? {
        return "timezone_offset=\(timezoneOffset)"
    }

    typealias ResponseType = Page<SCGModels.TransactionSummaryItem>
}

extension QueuedTransactionsSummaryListRequest {
    init(_ address: Address) {
        safeAddress = address.checksummed
    }
}

extension SafeClientGatewayService {
    func asyncQueuedTransactionsSummaryList(address: Address, completion: @escaping (Result<QueuedTransactionsSummaryListRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: QueuedTransactionsSummaryListRequest(address), completion: completion)
    }

    func asyncQueuedTransactionsSummaryList(pageUri: String, completion: @escaping (Result<QueuedTransactionsSummaryListRequest.ResponseType, Error>) -> Void) throws -> URLSessionTask? {
        asyncExecute(request: try PagedRequest<SCGModels.TransactionSummaryItem>(pageUri), completion: completion)
    }
}
