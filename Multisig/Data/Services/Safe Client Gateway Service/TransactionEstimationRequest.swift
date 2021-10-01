//
//  TransactionEstimationRequest.swift
//  Multisig
//
//  Created by Moaaz on 10/1/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionEstimationRequest: JSONRequest {
    private let safeAddress: String
    private let chainId: String
    
    var httpMethod: String { "GET" }
    var urlPath: String { "/v1/chains/\(chainId)/safes/\(safeAddress)/multisig-transactions/estimations" }
    typealias ResponseType = SCGModels.TransactionEstimation
}

extension TransactionEstimationRequest {
    init(_ safeAddress: Address, chainId: String) {
        self.init(safeAddress: safeAddress.checksummed, chainId: chainId)
    }
}

extension SafeClientGatewayService {
    func asyncTransactionEstimation(safeAddress: Address,
                       chainId: String,
                       completion: @escaping (Result<SCGModels.TransactionEstimation, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: TransactionEstimationRequest(safeAddress, chainId: chainId), completion: completion)
    }

    func syncTransactionEstimation(safeAddress: Address, chainId: String) throws -> SCGModels.TransactionEstimation {
        try execute(request: TransactionEstimationRequest(safeAddress, chainId: chainId))
    }
}
