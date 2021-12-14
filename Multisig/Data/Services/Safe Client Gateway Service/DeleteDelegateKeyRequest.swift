//
//  DeleteDelegateKeyRequest.swift
//  Multisig
//
//  Created by Moaaz on 12/7/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct DeleteDelegateKeyRequest: JSONRequest {
    let chainId: String
    var delegate: String
    var delegator: String
    var signature: String

    var httpMethod: String { "DELETE" }

    var urlPath: String { "/v1/chains/\(chainId)/delegates/\(delegate)" }

    typealias ResponseType = EmptyResponse
    struct EmptyResponse: Decodable { }

    enum CodingKeys: String, CodingKey {
        case delegate, delegator, signature
    }
}

extension SafeClientGatewayService {

    @discardableResult
    func asyncDeleteDelegate(
        owner: Address,
        delegate: Address,
        signature: String,
        chainId: String,
        completion: @escaping (Result<DeleteDelegateKeyRequest.ResponseType, Error>) -> Void
    ) -> URLSessionTask? {
        asyncExecute(request: DeleteDelegateKeyRequest(chainId: chainId,
                                                       delegate: delegate.checksummed,
                                                       delegator: owner.checksummed,
                                                       signature: signature),
                     completion: completion)
    }
}
