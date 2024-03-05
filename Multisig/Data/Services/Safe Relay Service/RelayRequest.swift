//
//  RelayRequest.swift
//  Multisig
//
//  Created by Vitaly on 05.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

struct RelayRequest: JSONRequest {
    let chainId: String
    let to: String          // Safe address
    let data: String        // Transaction data
    let gasLimit: String?   // Desired gas limit
    let version: String

    var httpMethod: String { "POST" }

    var urlPath: String { "/v1/chains/\(chainId)/relay" }

    typealias ResponseType = RelayTask
}


struct RelayTask: Decodable {
    let taskId: String?
}

extension SafeGelatoRelayService {
    
    @discardableResult
    func asyncRelayTransaction(
        chainId: String,
        to: Address,
        txData: String,
        gasLimit: String? = nil,
        version: String,
        completion: @escaping (Result<RelayRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {

            return asyncExecute(
                request: RelayRequest(
                    chainId: chainId,
                    to: to.checksummed,
                    data: txData,
                    gasLimit: gasLimit,
                    version: version
                ),
                completion: completion
            )
    }

    @discardableResult
    func relayTransaction(
        chainId: String,
        to: Address,
        txData: String,
        gasLimit: String? = nil,
        version: String
    ) throws  -> RelayTask? {

            let request = RelayRequest(
                chainId: chainId,
                to: to.checksummed,
                data: txData,
                gasLimit: gasLimit,
                version: version
            )

            return try execute(request: request)
    }
}
