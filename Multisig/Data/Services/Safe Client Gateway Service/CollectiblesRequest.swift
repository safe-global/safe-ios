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
    let chainId: Int
    
    var httpMethod: String { "GET" }
    var urlPath: String { "/\(chainId)/v1/safes/\(address)/collectibles/" }

    typealias ResponseType = [Collectible]
}

extension CollectiblesRequest {
    init(address: Address, chainId: Int) {
        self.address = address.checksummed
        self.chainId = chainId
    }
}

extension SafeClientGatewayService {
    func collectibles(at address: Address) throws -> [Collectible] {
        try execute(request: CollectiblesRequest(address: address, chainId: chainId))
    }

    func asyncCollectibles(at address: Address,
                           completion: @escaping (Result<[Collectible], Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: CollectiblesRequest(address: address, chainId: chainId), completion: completion)
    }
}
