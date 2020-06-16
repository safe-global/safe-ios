//
//  Transaction+Status.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

enum TransactionStatus {
    case success
    case pending
    case canceled
    case failed
    case waitingConfirmation
    case waitingExecution

    var title: String {
        switch self {
        case .waitingExecution:
            return "Awaiting execution"
        case .waitingConfirmation:
            return "Awaiting confirmations"
        case .pending:
             return "Pending"
        case .failed:
            return "Failed"
        case .canceled:
            return "Canceled"
        case .success:
            return "Success"
        }
    }
}

extension Transaction {

    func status(safeNonce: UInt256, safeThreshold: UInt256) -> TransactionStatus {
        // tx-es without nonce are external transactions that are
        // already executed successfully.
        guard let nonce = nonce?.value else { return .success }
        let confirmationCount = confirmations?.count ?? 0
        let threshold = confirmationsRequired?.value ?? safeThreshold

        if isExecuted == true && isSuccessful == true {
            return .success
        } else if isExecuted == true && isSuccessful != true {
            return .failed
        } else if isExecuted != true && nonce < safeNonce {
            return .canceled
        } else if isExecuted != true && nonce >= safeNonce && confirmationCount < threshold {
            return .waitingConfirmation
        } else if isExecuted != true && nonce >= safeNonce && confirmationCount >= threshold {
            return .waitingExecution
        } else {
            return .pending
        }
    }
}
