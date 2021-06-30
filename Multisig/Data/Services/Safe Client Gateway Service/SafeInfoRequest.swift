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
    let chainId: Int
    
    var httpMethod: String { "GET" }
    var urlPath: String { "/\(chainId)/v1/safes/\(safeAddress)/" }

    typealias ResponseType = SCGModels.SafeInfoExtended
}

extension SafeInfoRequest {
    init(_ safe: Safe) {
        self.init(safeAddress: (try! Address(from: safe.address!)).checksummed,
                  chainId: safe.network!.id)
    }

    init(_ address: Address, chainId: Int) {
        self.init(safeAddress: address.checksummed, chainId: chainId)
    }
}

extension SafeClientGatewayService {
    func syncSafeInfo(safe: Safe) throws -> SCGModels.SafeInfoExtended {
        try execute(request: SafeInfoRequest(safe))
    }

    func asyncSafeInfo(safe: Safe,
                       completion: @escaping (Result<SCGModels.SafeInfoExtended, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: SafeInfoRequest(safe), completion: completion)
    }

    func asyncSafeInfo(safeAddress: Address,
                       chainId: Int,
                       completion: @escaping (Result<SCGModels.SafeInfoExtended, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: SafeInfoRequest(safeAddress, chainId: chainId), completion: completion)
    }
}
