//
//  TransactionEstimationRequest.swift
//  Multisig
//
//  Created by Moaaz on 10/1/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionEstimationRequest: JSONRequest {
    var to: String
    var value: String
    var data: String
    var operation: Int

    let chainId: String
    let safeAddress: String
    
    var httpMethod: String { "POST" }

    var urlPath: String { "/v2/chains/\(chainId)/safes/\(safeAddress)/multisig-transactions/estimations"
    }

    typealias ResponseType = SCGModels.TransactionEstimation

    enum CodingKeys: String, CodingKey {
        case to, value, data, operation
    }
}

extension SafeClientGatewayService {
    func asyncTransactionEstimation(
        chainId: String,
        safeAddress: Address,
        to: Address,
        value: UInt256,
        data: Data?,
        operation: SCGModels.Operation,
        completion: @escaping (Result<SCGModels.TransactionEstimation, Error>
        ) -> Void) -> URLSessionTask? {
        asyncExecute(
            request: TransactionEstimationRequest(to: to.checksummed,
                                                  value: String(value),
                                                  data: data?.toHexStringWithPrefix() ?? "",
                                                  operation: operation.rawValue,
                                                  chainId: chainId,
                                                  safeAddress: safeAddress.checksummed),
            completion: completion)
    }

    func syncTransactionEstimation(
        chainId: String,
        safeAddress: Address,
        to: Address,
        value: UInt256,
        data: Data?,
        operation: SCGModels.Operation
    ) throws -> SCGModels.TransactionEstimation {
        try execute(
            request: TransactionEstimationRequest(to: to.checksummed,
                                                  value: String(value),
                                                  data: data?.toHexStringWithPrefix() ?? "",
                                                  operation: operation.rawValue,
                                                  chainId: chainId,
                                                  safeAddress: safeAddress.checksummed)
        )
    }
}
