//
//  TransactionByNonceRequest.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 05.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionByNonceRequest: JSONRequest {
    let safe: AddressString
    let nonce: UInt256String

    var httpMethod: String { "GET" }
    var urlPath: String { "/api/v1/safes/\(safe)/multisig-transactions/" }
    var query: String? { "nonce=\(nonce)" }

    typealias ResponseType = Page<Transaction>
}

extension SafeTransactionService {
    static func transaction(nonce: UInt256String, safe: AddressString, networkId: String) throws -> Transaction? {
        let page = try execute(request: TransactionByNonceRequest(safe: safe, nonce: nonce), networkId: networkId)
        guard !page.results.isEmpty else { return nil }
        return page.results[0]
    }
}
