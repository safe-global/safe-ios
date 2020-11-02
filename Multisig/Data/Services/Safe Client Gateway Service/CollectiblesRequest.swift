//
//  CollectiblesRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct CollectiblesRequest: JSONRequest {
    let address: String

    var httpMethod: String { return "GET" }
    var urlPath: String { return "/v1/safes/\(address)/collectibles/" }

    typealias Response = [Collectible]
    typealias ResponseType = Response

    init(address: Address) {
        self.address = address.checksummed
    }
}

extension SafeClientGatewayService {
    func collectibles(at address: Address) throws -> CollectiblesRequest.Response {
       try execute(request: CollectiblesRequest(address: address))
    }
}
