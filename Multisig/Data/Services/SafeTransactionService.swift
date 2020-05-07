//
//  SafTransactionService.swift
//  Multisig
//
//  Created by Moaaz on 5/7/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class SafeTransactionService {
    private let logger: Logger
    private let httpClient: JSONHTTPClient

    init(url: URL, logger: Logger) {
        self.logger = logger
        httpClient = JSONHTTPClient(url: url, logger: logger)
    }

    func safeInfo(at address: String) throws -> SafeStatusRequest.Response {
        return try httpClient.execute(request: SafeStatusRequest(address: address))
    }
}

struct SafeStatusRequest: JSONRequest {
    let address: String

    var httpMethod: String { return "GET" }
    var urlPath: String { return "/api/v1/safes/\(address)/" }

    typealias ResponseType = Response

    init(address: String) {
        self.address = address
    }

    struct Response: Decodable {
        let address: String
        let masterCopy: String
        let nonce: Int
        let threshold: Int
        let owners: [String]
        let modules: [String]
        let fallbackHandler: String
        let version: String
        
        init(address: String,
                    masterCopy: String,
                    nonce: Int,
                    threshold: Int,
                    owners: [String],
                    modules: [String],
                    fallbackHandler: String,
                    version: String) {
            self.address = address
            self.masterCopy = masterCopy
            self.nonce = nonce
            self.threshold = threshold
            self.owners = owners
            self.modules = modules
            self.fallbackHandler = fallbackHandler
            self.version = version
        }
    }
}
