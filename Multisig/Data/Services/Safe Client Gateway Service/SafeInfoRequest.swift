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
    let networkId: Int
    
    var httpMethod: String { "GET" }
    var urlPath: String { "/\(networkId)/v1/safes/\(safeAddress)/" }

    typealias ResponseType = SCGModels.SafeInfoExtended
}

extension SafeInfoRequest {
    init(_ safeAddress: Address, networkId: Int) {
        self.init(safeAddress: safeAddress.checksummed, networkId: networkId)
    }
}

extension SafeClientGatewayService {
    func syncSafeInfo(safeAddress: Address, networkId: Int) throws -> SCGModels.SafeInfoExtended {
        try execute(request: SafeInfoRequest(safeAddress, networkId: networkId))
    }

    func asyncSafeInfo(safeAddress: Address,
                       networkId: Int,
                       completion: @escaping (Result<SCGModels.SafeInfoExtended, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: SafeInfoRequest(safeAddress, networkId: networkId), completion: completion)
    }
}
