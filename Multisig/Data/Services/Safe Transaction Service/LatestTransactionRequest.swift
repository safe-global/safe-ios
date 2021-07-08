//
//  LatestTransactionRequest.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 03.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Get transaction with the highest nonce. 'multisig-transactions' results already sorted by nonce.
struct LatestTransactionRequest: JSONRequest {
    let safe: AddressString

    let limit = 1
    var httpMethod: String { "GET" }
    var urlPath: String { "/api/v1/safes/\(safe)/multisig-transactions/" }
    var query: String? { "limit=\(limit)" }

    typealias ResponseType = Page<Transaction>
}

extension SafeTransactionService {
    static func latestTransaction(for safe: AddressString, networkId: String) throws -> Transaction? {
        let page = try execute(request: LatestTransactionRequest(safe: safe), networkId: networkId)
        guard !page.results.isEmpty else { return nil }
        return page.results[0]
    }
}
