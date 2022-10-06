//
//  AllocationsRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 23.08.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct AllocationsRequest: JSONRequest {
    var account: Address
    var chainId: String

    var httpMethod: String { "GET" }

    var urlPath: String {
        "/allocations/\(chainId)/\(account.checksummed).json"
    }

    typealias ResponseType = [Allocation]

    func encode(to encoder: Encoder) throws {
        // empty
    }
}

extension SafeClaimingService {
    func asyncAllocations(account: Address, chainId: String, completion: @escaping (Result<AllocationsRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: AllocationsRequest(account: account, chainId: chainId), completion: completion)
    }
}
