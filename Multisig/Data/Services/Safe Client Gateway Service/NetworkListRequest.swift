//
//  ChainsRequest.swift
//  Multisig
//
//  Created by Moaaz on 6/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct NetworkListRequest: JSONRequest {
    var httpMethod: String {
        "GET"
    }

    var urlPath: String {
        "/v1/chains"
    }

    var query: String? {
        return "limit=1000"
    }

    typealias ResponseType = Page<SCGModels.Network>
}

extension SafeClientGatewayService {
    @discardableResult
    func asyncNetworks(completion: @escaping (Result<NetworkListRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: NetworkListRequest(), completion: completion)
    }

    func asyncNetworks(pageUri: String, completion: @escaping (Result<NetworkListRequest.ResponseType, Error>) -> Void) throws -> URLSessionTask? {
        asyncExecute(request: try PagedRequest<SCGModels.Network>(pageUri), completion: completion)
    }
}
