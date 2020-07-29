//
//  TransactionDetailsRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 28.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionDetailsRequest: JSONRequest {
    let transactionHash: String
    var httpMethod: String { "GET" }
    var urlPath: String { "/api/v1/transactions/\(transactionHash)/" }
    typealias ResponseType = Transaction
}

extension TransactionDetailsRequest {
    init(transactionHash: Data) {
        self.transactionHash = transactionHash.toHexStringWithPrefix()
    }

    init(transactionHash: DataString) {
        self.transactionHash = transactionHash.data.toHexStringWithPrefix()
    }
}

extension SafeTransactionService {
    func transaction(hash: Data) throws -> TransactionDetailsRequest.ResponseType {
        try execute(request: TransactionDetailsRequest(transactionHash: hash))
    }
}
