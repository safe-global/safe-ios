//
//  CreateDelegateRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.10.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

#warning("TODO: unconfirmed implementation.")
struct CreateDelegateRequest: JSONRequest {
    var httpMethod: String { "POST" }
    var urlPath: String { "/safes/delegates/" }

    typealias ResponseType = EmptyResponse

    struct EmptyResponse: Decodable { }

    var safe: String?
    var address: String
    var delegate: String
    // signature of hash: keccak(address + str(int(current_epoch // 3600)))
    var signature: String
    var label: String
}

extension SafeClientGatewayService {

    @discardableResult
    func createDelegate(
        safe: Address?,
        owner: Address,
        delegate: Address,
        signature: Data,
        label: String,
        completion: @escaping (Result<CreateDelegateRequest.ResponseType, Error>
    ) -> Void) -> URLSessionTask? {
        asyncExecute(request: CreateDelegateRequest(safe: safe?.checksummed,
                                                    address: owner.checksummed,
                                                    delegate: delegate.checksummed,
                                                    signature: signature.toHexStringWithPrefix(),
                                                    label: label),
                     completion: completion)
    }
}
