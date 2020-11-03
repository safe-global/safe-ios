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

    var httpMethod: String { "GET" }
    var urlPath: String { "/v1/safes/\(address)/collectibles/" }

    typealias ResponseType = [Collectible]
}

extension CollectiblesRequest {
    init(address: Address) {
        self.address = address.checksummed
    }
}

extension SafeClientGatewayService {
    func collectibles(at address: Address) throws -> [Collectible] {
       try execute(request: CollectiblesRequest(address: address))
    }

    func asyncCollectibles(at address: Address,
                           completion: @escaping (Result<[Collectible], Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: CollectiblesRequest(address: address), completion: completion)
    }
}
