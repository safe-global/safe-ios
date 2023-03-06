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
    let target: String      // Safe address
    let data: String        // Transaction data
    let gasLimit: String?   // Desired gas limit

    var httpMethod: String { "POST" }

    var urlPath: String { "/v1/relay" }

    typealias ResponseType = RelayTask
}


struct RelayTask: Decodable {
    let taskId: String?
}

extension SafeGelatoRelayService {

    @discardableResult
    func asyncRelayTransaction(
        transaction: Transaction,
        gasLimit: String? = nil,
        completion: @escaping (Result<RelayRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {

            return asyncExecute(
                request: RelayRequest(
                    chainId: transaction.chainId!,
                    target: transaction.safe!.address.checksummed,
                    data: transaction.data!.description,
                    gasLimit: gasLimit
                ),
                completion: completion
            )
    }

    @discardableResult
    func relayTransaction(
        transaction: Transaction,
        gasLimit: String? = nil) throws  -> RelayTask? {

            let request = RelayRequest(
                chainId: transaction.chainId!,
                target: transaction.safe!.address.checksummed,
                data: transaction.data!.description,
                gasLimit: gasLimit
            )

            return try execute(request: request)
    }
}
