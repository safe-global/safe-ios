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
    init(_ safe: Safe) {
        self.init(address: (try! Address(from: safe.address!)).checksummed,
                  chainId: safe.network!.id)
    }
}

extension SafeClientGatewayService {
    func asyncCollectibles(safe: Safe,
                           completion: @escaping (Result<[Collectible], Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: CollectiblesRequest(safe), completion: completion)
    }
}
