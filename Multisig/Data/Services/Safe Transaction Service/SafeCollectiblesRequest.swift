//
//  SafeCollectiblesRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

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

extension SafeTransactionService {
    func collectibles(at address: Address) throws -> SafeCollectiblesRequest.Response {
       try execute(request: SafeCollectiblesRequest(address: address))
    }
}
