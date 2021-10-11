//
//  CreateDelegateRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.10.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct CreateDelegateRequest: JSONRequest {
    var httpMethod: String { "POST" }
    var urlPath: String { "/delegates/" }

    typealias ResponseType = EmptyResponse

    struct EmptyResponse: Decodable { }

    var safe: String?
    var delegate: String
    var delegator: String
    // delegator's signature of hash: keccak(delegate + str(int(current_epoch // 3600)))
    var signature: String
    var label: String
}

extension SafeClientGatewayService {

    @discardableResult
    func asyncCreateDelegate(
        safe: Address?,
        owner: Address,
        delegate: Address,
        signature: Data,
        label: String,
        completion: @escaping (Result<CreateDelegateRequest.ResponseType, Error>
    ) -> Void) -> URLSessionTask? {
        asyncExecute(request: CreateDelegateRequest(safe: safe?.checksummed,
                                                    delegate: delegate.checksummed,
                                                    delegator: owner.checksummed,
                                                    signature: signature.toHexStringWithPrefix(),
                                                    label: label),
                     completion: completion)
    }
}
