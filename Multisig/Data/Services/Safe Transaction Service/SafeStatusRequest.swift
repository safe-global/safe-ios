//
//  SafeStatusRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct SafeStatusRequest: JSONRequest {
    let address: String

    var httpMethod: String { return "GET" }
    var urlPath: String { return "/api/v1/safes/\(address)/" }

    typealias ResponseType = Response

    init(address: Address) {
        self.address = address.checksummed
    }

    struct Response: Decodable {
        let address: AddressString
        let implementation: AddressString
        let nonce: UInt256String
        let threshold: UInt256String
        let owners: [AddressString]
        let modules: [AddressString]
        let fallbackHandler: AddressString
        let version: String

        enum CodingKeys: String, CodingKey {
            case address
            case implementation = "masterCopy"
            case nonce, threshold, owners, modules, fallbackHandler, version
        }
    }
}

extension SafeTransactionService {
    func safeInfo(at address: Address) throws -> SafeStatusRequest.Response {
        try execute(request: SafeStatusRequest(address: address))
    }

    func asyncSafeInfo(at address: Address,
                       completion: @escaping (Result<SafeStatusRequest.Response, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: SafeStatusRequest(address: address), completion: completion)
    }
}
