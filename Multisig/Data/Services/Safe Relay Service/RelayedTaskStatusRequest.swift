//
//  RelayedTransactionStatusRequest.swift
//  Multisig
//
//  Created by Mouaz on 4/8/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import BigInt

struct RelayedTaskStatusRequest: JSONRequest {
    let taskId: String

    var httpMethod: String { "GET" }

    var urlPath: String { "/tasks/status/\(taskId)" }

    typealias ResponseType = RelayedTaskStatus
}

struct RelayedTaskStatus: Decodable {
    let taskId: String?
    let chainId: String?
    let taskState: String?
    let creationDate: Date?
    let executionDate: Date?
    let transactionHash: Date?
    let blockNumber: BigInt?
    let lastCheckMessage: String?
}

extension GelatoRelayService {

    @discardableResult
    func asyncStatus(taskId: String,
                     completion: @escaping (Result<RelayedTaskStatusRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
            asyncExecute(request: RelayedTaskStatusRequest(taskId: taskId), completion: completion)
    }
}
