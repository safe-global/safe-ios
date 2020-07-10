//
//  TransactionsRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionsRequest: JSONRequest {
    let address: String
    let limit: Int
    let offset: Int
    var httpMethod: String { "GET" }
    var urlPath: String {
        "/api/v1/safes/\(address)/all-transactions/"
    }

    var query: String? {
        "limit=\(limit)&offset=\(offset)&queued=true"
    }

    typealias Response = PagedResponse<Transaction>
    typealias ResponseType = Response

    init(address: Address, limit: Int, offset: Int) {
        self.address = address.checksummed
        self.limit = limit
        self.offset = offset
    }
}

extension SafeTransactionService {
    func transactions(address: Address?, offset: Int = 0, limit: Int = 20) throws -> TransactionsRequest.Response {
        try execute(request: TransactionsRequest(address: address!, limit: limit, offset: offset))
    }

    func loadTransactionsPage(url: String) throws -> TransactionsRequest.Response? {
        guard let request = PagedRequest<Transaction>(url) else { return nil }
        return try execute(request: request)
    }
}
