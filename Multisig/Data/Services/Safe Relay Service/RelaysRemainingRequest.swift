//
//  RelaysRemainingRequest.swift
//  Multisig
//
//  Created by Vitaly on 05.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

struct RelaysRemainingRequest: JSONRequest {
    let chainId: String
    let safeAddress: String

    var httpMethod: String { "GET" }

    var urlPath: String { "/v1/relay/\(chainId)/\(safeAddress)" }

    typealias ResponseType = RelaysRemaining
}

extension RelaysRemainingRequest {
    init(chainId: String, safeAddress: Address) {
        self.init(chainId: chainId, safeAddress: safeAddress.checksummed)
    }
}

struct RelaysRemaining: Decodable {
    let remaining: Int
    let limit: Int
    let expiresAt: Date?
}

extension SafeGelatoRelayService {

    func asyncRelaysRemaining(
        chainId: String,
        safeAddress: Address, // doesn't have to be a Safe Address. In the case of a safe creation call it is an owner address
        completion: @escaping (Result<RelaysRemainingRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {

            return asyncExecute(
                request: RelaysRemainingRequest(
                    chainId: chainId,
                    safeAddress: safeAddress
                ),
                completion: completion
            )
    }
}
