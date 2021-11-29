//
//  GetDelegateRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 29.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct GetDelegateRequest: JSONRequest {
    let chainId: String
    var safe: String?
    var delegate: String?
    var delegator: String?
    var label: String?

    var httpMethod: String { "GET" }
    var urlPath: String { "/v1/chains/\(chainId)/delegates/" }

    typealias ResponseType = Page<SCGModels.KeyDelegate>
}

extension SafeClientGatewayService {
    func asyncCreateDelegate(
        chainId: String,
        safe: Address? = nil,
        delegator: Address? = nil,
        delegate: Address? = nil,
        label: String? = nil,
        completion: @escaping (Result<GetDelegateRequest.ResponseType, Error>) -> Void
    ) -> URLSessionTask? {
        asyncExecute(request: GetDelegateRequest(chainId: chainId,
                                                 safe: safe?.checksummed,
                                                 delegate: delegate?.checksummed,
                                                 delegator: delegator?.checksummed,
                                                 label: label),
                     completion: completion)
    }
}
