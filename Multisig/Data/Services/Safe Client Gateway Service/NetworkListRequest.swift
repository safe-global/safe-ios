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

    typealias ResponseType = [SCGModels.Network]
}

extension SafeClientGatewayService {
    @discardableResult
    func asyncNetworks(completion: @escaping (Result<NetworkListRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: NetworkListRequest(), completion: completion)
    }
}
