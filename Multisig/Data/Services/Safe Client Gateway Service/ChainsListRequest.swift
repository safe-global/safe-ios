//
//  ChainsRequest.swift
//  Multisig
//
//  Created by Moaaz on 6/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct ChainsListRequest: JSONRequest {
    var httpMethod: String {
        "GET"
    }

    var urlPath: String {
        "v1/chains"
    }

    typealias ResponseType = [SCGModels.Chain]
}

extension SafeClientGatewayService {
    @discardableResult
    func chains(completion: @escaping (Result<ChainsListRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: ChainsListRequest(), completion: completion)
    }
}
