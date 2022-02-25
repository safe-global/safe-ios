//
//  SafeInfoRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 3/17/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct SafeInfoRequest: JSONRequest {
    let safeAddress: String
    let chainId: String
    
    var httpMethod: String { "GET" }
    var urlPath: String { "/v1/chains/\(chainId)/safes/\(safeAddress)/" }

    typealias ResponseType = SCGModels.SafeInfoExtended
}

extension SafeInfoRequest {
    init(_ safeAddress: Address, chainId: String) {
        self.init(safeAddress: safeAddress.checksummed, chainId: chainId)
    }
}

extension SafeClientGatewayService {
    func syncSafeInfo(safeAddress: Address, chainId: String) throws -> SCGModels.SafeInfoExtended {
        try execute(request: SafeInfoRequest(safeAddress, chainId: chainId))
    }
    
    func asyncSafeInfo(safeAddress: Address,
                       chainId: String,
                       completion: @escaping (Result<SCGModels.SafeInfoExtended, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: SafeInfoRequest(safeAddress, chainId: chainId), completion: completion)
    }
}
