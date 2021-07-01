//
//  CollectiblesRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct CollectiblesRequest: JSONRequest {
    let safeAddress: String
    let networkId: Int
    
    var httpMethod: String { "GET" }
    var urlPath: String { "/\(networkId)/v1/safes/\(safeAddress)/collectibles/" }

    typealias ResponseType = [Collectible]
}

extension CollectiblesRequest {
    init(_ safeAddress: Address, networkId: Int) {
        self.init(safeAddress: safeAddress.checksummed,
                  networkId: networkId)
    }
}

extension SafeClientGatewayService {
    func asyncCollectibles(safeAddress: Address,
                           networkId: Int,
                           completion: @escaping (Result<[Collectible], Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: CollectiblesRequest(safeAddress, networkId: networkId), completion: completion)
    }
}
