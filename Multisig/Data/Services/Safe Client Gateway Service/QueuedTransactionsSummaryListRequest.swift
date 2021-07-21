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
    let chainId: String
    
    let timezoneOffset = TimeZone.currentOffest()
    var httpMethod: String { "GET" }
    var urlPath: String {
        "/v1/chains/\(chainId)/safes/\(safeAddress)/transactions/queued"
    }

    var query: String? {
        return "timezone_offset=\(timezoneOffset)"
    }

    typealias ResponseType = Page<SCGModels.TransactionSummaryItem>
}

extension QueuedTransactionsSummaryListRequest {
    init(_ safeAddress: Address, chainId: String) {
        self.init(safeAddress: safeAddress.checksummed, chainId: chainId)
    }
}

extension SafeClientGatewayService {
    func latestQueuedTransactionNonce(safeAddress: Address, chainId: String) throws -> UInt256String? {
        let page = try execute(request: QueuedTransactionsSummaryListRequest(safeAddress, chainId: chainId))
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
        chainId: String,
        completion: @escaping (Result<QueuedTransactionsSummaryListRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {

        asyncExecute(request: QueuedTransactionsSummaryListRequest(safeAddress, chainId: chainId), completion: completion)
    }

    func asyncQueuedTransactionsSummaryList(
        pageUri: String,
        completion: @escaping (Result<QueuedTransactionsSummaryListRequest.ResponseType, Error>) -> Void) throws -> URLSessionTask? {

        asyncExecute(request: try PagedRequest<SCGModels.TransactionSummaryItem>(pageUri), completion: completion)
    }
}
