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
    let networkId: String
    
    let timezoneOffset = TimeZone.currentOffest()
    var httpMethod: String { "GET" }
    var urlPath: String {
        "/v1/chains/\(networkId)/safes/\(safeAddress)/transactions/queued"
    }

    var query: String? {
        return "timezone_offset=\(timezoneOffset)"
    }

    typealias ResponseType = Page<SCGModels.TransactionSummaryItem>
}

extension QueuedTransactionsSummaryListRequest {
    init(_ safeAddress: Address, networkId: String) {
        self.init(safeAddress: safeAddress.checksummed, networkId: networkId)
    }
}

extension SafeClientGatewayService {
    func latestQueuedTransactionNonce(safeAddress: Address, networkId: String) throws -> UInt256String? {
        let page = try execute(request: QueuedTransactionsSummaryListRequest(safeAddress, networkId: networkId))
        for item in page.results {
            if case SCGModels.TransactionSummaryItem.transaction(let transaction) = item,
               let executionInfo = transaction.transaction.executionInfo,
               case SCGModels.ExecutionInfo.multisig(let multisig) = executionInfo {
                return multisig.nonce
            }
        }
        return nil
    }

    func asyncQueuedTransactionsSummaryList(
        safeAddress: Address,
        networkId: String,
        completion: @escaping (Result<QueuedTransactionsSummaryListRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {

        asyncExecute(request: QueuedTransactionsSummaryListRequest(safeAddress, networkId: networkId), completion: completion)
    }

    func asyncQueuedTransactionsSummaryList(
        pageUri: String,
        completion: @escaping (Result<QueuedTransactionsSummaryListRequest.ResponseType, Error>) -> Void) throws -> URLSessionTask? {

        asyncExecute(request: try PagedRequest<SCGModels.TransactionSummaryItem>(pageUri), completion: completion)
    }
}
