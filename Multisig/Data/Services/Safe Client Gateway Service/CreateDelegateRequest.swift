//
//  CreateDelegateRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.10.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Registers a delegate address for a delegator address in the backend
///
/// This is used for push notification registration and can be used for other functions, such as proposing transactions.
/// Delegator signs a message containing delegate address. Then, the delegate would be allowed to register
/// for push notifications and provide its signature. This way the app doesn't need repeated access to the
/// delegator's key and can use the delegate key instead. This won't affect signing transactions, but it is
/// useful for other convenience features, such as push notifications.
struct CreateDelegateRequest: JSONRequest {
    var httpMethod: String { "POST" }
    var urlPath: String { "/v1/chains/\(chainId)/delegates/" }

    typealias ResponseType = EmptyResponse

    struct EmptyResponse: Decodable { }

    var safe: String?
    var delegate: String
    var delegator: String
    // delegator's signature of hash: keccak(delegate + str(int(current_epoch // 3600)))
    var signature: String
    var label: String
    let chainId: String
}

extension SafeClientGatewayService {

    @discardableResult
    func asyncCreateDelegate(
        safe: Address?,
        owner: Address,
        delegate: Address,
        signature: Data,
        label: String,
        chainId: String,
        completion: @escaping (Result<CreateDelegateRequest.ResponseType, Error>) -> Void
    ) -> URLSessionTask? {
        asyncExecute(request: CreateDelegateRequest(safe: safe?.checksummed,
                                                    delegate: delegate.checksummed,
                                                    delegator: owner.checksummed,
                                                    signature: signature.toHexStringWithPrefix(),
                                                    label: label,
                                                    chainId: chainId),
                     completion: completion)
    }
}
