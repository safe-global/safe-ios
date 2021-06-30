//
//  SafeInfoRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 3/17/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct SafeInfoRequest: JSONRequest {
    var safeAddress: String
    let chainId: Int
    
    var httpMethod: String { "GET" }
    var urlPath: String { "/\(chainId)/v1/safes/\(safeAddress)/" }

    typealias ResponseType = SCGModels.SafeInfoExtended
}

extension SafeInfoRequest {
    init(_ address: Address, chainId: Int) {
        self.init(safeAddress: address.checksummed, chainId: chainId)
    }
}

extension SafeClientGatewayService {
    func syncSafeInfo(address: Address) throws -> SCGModels.SafeInfoExtended {
        try execute(request: SafeInfoRequest(address, chainId: chainId))
    }

    func asyncSafeInfo(address: Address, completion: @escaping (Result<SCGModels.SafeInfoExtended, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: SafeInfoRequest(address, chainId: chainId), completion: completion)
    }
}
