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

    var httpMethod: String { "GET" }

    var urlPath: String {
        "/claiming-app-data/resources/data/allocations/\(account.hexadecimal).json"
    }

    typealias ResponseType = [Allocation]

    func encode(to encoder: Encoder) throws {
        // empty
    }
}

extension SafeClaimingService {
    func asyncAllocations(account: Address, completion: @escaping (Result<AllocationsRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: AllocationsRequest(account: account), completion: completion)
    }
}
