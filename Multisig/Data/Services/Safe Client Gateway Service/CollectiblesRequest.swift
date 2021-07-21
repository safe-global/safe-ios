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
    let chainId: String
    
    var httpMethod: String { "GET" }
    var urlPath: String { "/v1/chains/\(chainId)/safes/\(safeAddress)/collectibles/" }

    typealias ResponseType = [Collectible]
}

extension CollectiblesRequest {
    init(_ safeAddress: Address, chainId: String) {
        self.init(safeAddress: safeAddress.checksummed,
                  chainId: chainId)
    }
}

extension SafeClientGatewayService {
    func asyncCollectibles(safeAddress: Address,
                           chainId: String,
                           completion: @escaping (Result<[Collectible], Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: CollectiblesRequest(safeAddress, chainId: chainId), completion: completion)
    }
}
