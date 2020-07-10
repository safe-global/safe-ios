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

    var jsonDecoder: JSONDecoder {
        httpClient.jsonDecoder
    }

    init(url: URL, logger: Logger) {
        self.url = url
        self.logger = logger
        httpClient = JSONHTTPClient(url: url, logger: logger)
        // 2020-01-22T13:11:59.838510Z
        let formatter1 = DateFormatter()
        formatter1.timeZone = TimeZone(abbreviation: "UTC")
        formatter1.locale = Locale(identifier: "en_US_POSIX")
        formatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        // 2020-01-22T13:11:48Z
        let formatter2 = DateFormatter()
        formatter2.timeZone = TimeZone(abbreviation: "UTC")
        formatter2.locale = Locale(identifier: "en_US_POSIX")
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

    func safeInfo(at address: Address) throws -> SafeStatusRequest.Response {
        try httpClient.execute(request: SafeStatusRequest(address: address))
    }

    func safeBalances(at address: Address) throws -> [SafeBalancesRequest.Response] {
        try httpClient.execute(request: SafeBalancesRequest(address: address))
    }

    func transactions(address: Address?, offset: Int = 0, limit: Int = 20) throws -> TransactionsRequest.Response {
        try httpClient.execute(request: TransactionsRequest(address: address!, limit: limit, offset: offset))
    }

    func loadTransactionsPage(url: String) throws -> TransactionsRequest.Response? {
        guard let request = PagedRequest<Transaction>(url) else { return nil }
        return try httpClient.execute(request: request)
    }

    func collectibles(at address: Address) throws -> SafeCollectiblesRequest.Response {
       try httpClient.execute(request: SafeCollectiblesRequest(address: address))
    }

    func tokens() throws -> TokensRequest.Response {
        try httpClient.execute(request: TokensRequest())
    }

}

struct SafeStatusRequest: JSONRequest {
    let address: String

    var httpMethod: String { return "GET" }
    var urlPath: String { return "/api/v1/safes/\(address)/" }

    typealias ResponseType = Response

    init(address: Address) {
        self.address = address.checksummed
    }

    struct Response: Decodable {
        let address: AddressString
        let masterCopy: AddressString
        let nonce: UInt256String
        let threshold: UInt256String
        let owners: [AddressString]
        let modules: [AddressString]
        let fallbackHandler: AddressString
        let version: String
    }
}

struct SafeBalancesRequest: JSONRequest {
    let address: String

    var httpMethod: String { return "GET" }
    var urlPath: String { return "/api/v1/safes/\(address)/balances/usd/" }

    typealias ResponseType = [Response]

    init(address: Address) {
        self.address = address.checksummed
    }

    struct Response: Decodable {
        let tokenAddress: AddressString? // nil == Ether
        let token: Token? // nil == Ether
        let balance: UInt256String
        let balanceUsd: String

        struct Token: Decodable {
            let name: String
            let symbol: String
            let decimals: UInt256String
        }
    }
}

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

struct SafeCollectiblesRequest: JSONRequest {
    let address: String

    var httpMethod: String { return "GET" }
    var urlPath: String { return "/api/v1/safes/\(address)/collectibles/" }

    typealias Response = [Collectible]
    typealias ResponseType = Response

    init(address: Address) {
        self.address = address.checksummed
    }
}

struct TokensRequest: JSONRequest {

    let limit: Int = 3000
    let offset: Int = 0

    var httpMethod: String { "GET" }
    var urlPath: String { "/api/v1/tokens/" }

    var query: String? {
        return "limit=\(limit)&offset=\(offset)"
    }

    typealias Response = PagedResponse<Token>
    typealias ResponseType = Response

    struct Token: Decodable {
        var address: AddressString
        var logoUri: String?
        var name: String
        var symbol: String
        var decimals: UInt256String
        var trusted: Bool?
    }

}
