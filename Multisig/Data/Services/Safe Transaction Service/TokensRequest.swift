//
//  TokensRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

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
        var type: TokenType?
        var address: AddressString
        var name: String
        var symbol: String
        var decimals: UInt256String
        var logoUri: String?
    }

}

extension SafeTransactionService {
    func tokens() throws -> TokensRequest.Response {
        try execute(request: TokensRequest())
    }
}

extension Token {

    init(_ token: TokensRequest.Token) {
        type = token.type ?? .erc20
        address = token.address.address
        logo = token.logoUri.flatMap { URL(string: $0) }
        name = token.name
        symbol = token.symbol
        decimals = token.decimals.value
    }

}
