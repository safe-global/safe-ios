//
//  DeleteDelegateKeyRequest.swift
//  Multisig
//
//  Created by Moaaz on 12/7/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct DeleteDelegateKeyRequest: JSONRequest {
    var httpMethod: String { "DELETE" }
    var urlPath: String { "/v1/chains/\(chainId)/delegates/" }

    typealias ResponseType = EmptyResponse

    struct EmptyResponse: Decodable { }

    var safe: String?
    var delegate: String
    var delegator: String
    var signature: String
    let chainId: String
}

extension SafeClientGatewayService {

    @discardableResult
    func asyncDeleteDelegate(
        safe: Address?,
        owner: Address,
        delegate: Address,
        signature: String,
        chainId: String,
        completion: @escaping (Result<DeleteDelegateKeyRequest.ResponseType, Error>) -> Void
    ) -> URLSessionTask? {
        asyncExecute(request: DeleteDelegateKeyRequest(safe: safe?.checksummed,
                                                       delegate: delegate.checksummed,
                                                       delegator: owner.checksummed,
                                                       signature: signature,
                                                       chainId: chainId),
                     completion: completion)
    }
}
