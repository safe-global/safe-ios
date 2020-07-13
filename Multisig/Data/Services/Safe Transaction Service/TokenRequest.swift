//
//  TokenRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TokenRequest: JSONRequest {

    var httpMethod: String { "GET" }
    var urlPath: String { "/api/v1/tokens/\(address)" }

    let address: String

    init(_ address: Address) {
        self.address = address.checksummed
    }

    typealias ResponseType = TokensRequest.Token

}

extension SafeTransactionService {
    func token(_ address: Address) throws -> TokenRequest.ResponseType {
        try execute(request: TokenRequest(address))
    }
}
