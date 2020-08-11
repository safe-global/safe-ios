//
//  CreationTransactionRequest.swift
//  Multisig
//
//  Created by Moaaz on 8/10/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct CreationTransactionRequest: JSONRequest {

    let address: String
    var httpMethod: String { "GET" }
    var urlPath: String {
        "/api/v1/safes/\(address)/creation/"
    }

    typealias Response = CreationTransaction
    typealias ResponseType = Response

    init(address: Address) {
        self.address = address.checksummed
    }
}

extension SafeTransactionService {
    func creationTransaction(address: Address) throws -> CreationTransactionRequest.Response {
        try execute(request: CreationTransactionRequest(address: address))
    }
}
