//
//  ConfirmTransactionRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 23.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct ConfirmTransactionRequest: JSONRequest {
    var safeTxHash: String
    var signedSafeTxHash: String
    let chainId: String
    
    var httpMethod: String { "POST" }
    var urlPath: String { "/v1/chains/\(chainId)/transactions/\(safeTxHash)/confirmations" }
    typealias ResponseType = SCGModels.TransactionDetails

    enum CodingKeys: String, CodingKey {
        case signedSafeTxHash
    }
}

extension SafeClientGatewayService {
    func asyncConfirm(safeTxHash: String,
                      signature: String,
                      chainId: String,
                      completion: @escaping (Result<SCGModels.TransactionDetails, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: ConfirmTransactionRequest(safeTxHash: safeTxHash,
                                                        signedSafeTxHash: signature,
                                                        chainId: chainId),
                     completion: completion)
    }
}
