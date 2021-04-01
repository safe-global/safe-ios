//
//  SafeInfoRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 3/17/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct SafeInfoRequest: JSONRequest {
    var safeAddress: String

    let httpMethod: String = "GET"
    var urlPath: String { "/v1/safes/\(safeAddress)/" }

    typealias ResponseType = SCGModels.SafeInfoExtended
}

extension SafeInfoRequest {
    init(_ address: Address) {
        self.init(safeAddress: address.checksummed)
    }
}

extension SafeClientGatewayService {
    func asyncSafeInfo(address: Address, completion: @escaping (Result<SCGModels.SafeInfoExtended, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: SafeInfoRequest(address), completion: completion)
    }
}
