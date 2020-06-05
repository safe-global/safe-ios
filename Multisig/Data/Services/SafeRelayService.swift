//
//  SafeRelayService.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class SafeRelayService {

    var url: URL
    private let logger: Logger
    private let httpClient: JSONHTTPClient

    init(url: URL, logger: Logger) {
        self.url = url
        self.logger = logger
        httpClient = JSONHTTPClient(url: url, logger: logger)
    }

    func tokens() throws -> TokensRequest.Response {
        try httpClient.execute(request: TokensRequest())
    }
}

class TokenRegistry {

    let response: TokensRequest.Response

    init(_ response: TokensRequest.Response) {
        self.response = response
    }

    func cachedToken(address: String) -> TokensRequest.Token? {
        response.results.first { $0.address == address }
    }

//    func

//
//    subscript(address: String) -> TokensRequest.Token? {
//
//    }
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
        let address: String
        let logoUri: URL?
        let `default`: Bool?
        let name: String
        let symbol: String
        let description: String?
        let decimals: Int
        let websiteUri: URL?
        let gas: Bool?
    }

}

struct PagedResponse<Item: Decodable>: Decodable {
    let count: Int
    let next: URL?
    let previous: URL?
    let results: [Item]
}
