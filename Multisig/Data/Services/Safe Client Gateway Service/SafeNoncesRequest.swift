//
//  SafeNoncesRequest.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 02.11.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

struct SafeNoncesRequest: JSONRequest {
    var safeAddress: String
    var chainId: String
    var httpMethod: String { "GET" }
    
    var urlPath: String {
        "/v1/chains/\(chainId)/safes/\(safeAddress)/nonces"
    }
    
    typealias ResponseType = SCGModels.Nonces

}

extension SafeClientGatewayService {
    func asyncSafeNonces(
        chainId: String,
        safeAddress: Address,
        completion: @escaping (Result<SCGModels.Nonces, Error>) -> Void
    ) -> URLSessionTask? {
        asyncExecute(
            request: SafeNoncesRequest(safeAddress: safeAddress.checksummed,
                                       chainId: chainId),
            completion: completion
        )
    }
}
