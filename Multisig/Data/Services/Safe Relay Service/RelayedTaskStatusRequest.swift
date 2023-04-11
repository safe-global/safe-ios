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

    typealias ResponseType = StatusResponseObject
}

struct StatusResponseObject: Decodable {
    let task: RelayedTaskStatus
}

struct RelayedTaskStatus: Decodable {
    let taskId: String?
    let taskState: Status?
    let transactionHash: String?
    let lastCheckMessage: String?

    enum Status: String, Decodable {
        case awaitingChecking = "CheckPending"
        case awaitingExecution = "ExecPending"
        case awaitingConfirmation = "WaitingForConfirmation"
        case success = "ExecSuccess"
        case cancelled = "Cancelled"
        case reverted = "ExecReverted"
    }
}

extension GelatoRelayService {

    @discardableResult
    func asyncStatus(taskId: String,
                     completion: @escaping (Result<RelayedTaskStatusRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
            asyncExecute(request: RelayedTaskStatusRequest(taskId: taskId), completion: completion)
    }
}
