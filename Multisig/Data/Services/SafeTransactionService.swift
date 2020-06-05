//
//  SafTransactionService.swift
//  Multisig
//
//  Created by Moaaz on 5/7/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class SafeTransactionService {

    var url: URL
    private let logger: Logger
    private let httpClient: JSONHTTPClient

    init(url: URL, logger: Logger) {
        self.url = url
        self.logger = logger
        httpClient = JSONHTTPClient(url: url, logger: logger)
        // 2020-01-22T13:11:59.838510Z
        let formatter1 = DateFormatter()
        formatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        // 2020-01-22T13:11:48Z
        let formatter2 = DateFormatter()
        formatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        httpClient.jsonDecoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.custom { (decoder) -> Date in
            let c = try decoder.singleValueContainer()
            let str = try c.decode(String.self)
            if let date = formatter1.date(from: str) {
                return date
            } else if let date = formatter2.date(from: str) {
                return date
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                        debugDescription: "Date! \(str)"))
            }
        }
    }

    func safeInfo(at address: String) throws -> SafeStatusRequest.Response {
        return try httpClient.execute(request: SafeStatusRequest(address: address))
    }

    func safeBalances(at address: String) throws -> [SafeBalancesRequest.Response] {
        return try httpClient.execute(request: SafeBalancesRequest(address: address))
    }

    func transactions(address: String) throws -> TransactionsRequest.Response {
        return try httpClient.execute(request: TransactionsRequest(address: address))
    }
}

struct SafeStatusRequest: JSONRequest {
    let address: String

    var httpMethod: String { return "GET" }
    var urlPath: String { return "/api/v1/safes/\(address)/" }

    typealias ResponseType = Response

    init(address: String) {
        self.address = address
    }

    struct Response: Decodable {
        let address: String
        let masterCopy: String
        let nonce: Int
        let threshold: Int
        let owners: [String]
        let modules: [String]
        let fallbackHandler: String
        let version: String
    }
}

struct SafeBalancesRequest: JSONRequest {
    let address: String

    var httpMethod: String { return "GET" }
    var urlPath: String { return "/api/v1/safes/\(address)/balances/usd/" }

    typealias ResponseType = [Response]

    init(address: String) {
        self.address = address
    }

    struct Response: Decodable {
        let tokenAddress: String? // nil == Ether
        let token: Token? // nil == Ether
        let balance: String
        let balanceUsd: String

        struct Token: Decodable {
            let name: String
            let symbol: String
            let decimals: Int
        }
    }
}

struct TransactionsRequest: JSONRequest {
    let address: String
    let limit: Int = 100
    let offset: Int = 0
    var httpMethod: String { return "GET" }
    var urlPath: String { return "/api/v1/safes/\(address)/all-transactions/" }

    typealias ResponseType = Response

    init(address: String) {
        self.address = address
    }

    var query: String? {
        return "limit=\(limit)&offset=\(offset)"
    }

    struct Response: Decodable {
        let count: Int
        let previous: String?
        let next: String?
        let results: [Transaction]
    }
}
