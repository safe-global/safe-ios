//
//  TransactionStatus+ViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 17.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension TransactionStatus {

    static let queueStatuses = [TransactionStatus.pending, .waitingConfirmation, .waitingExecution]
    static let historyStatuses = [TransactionStatus.success, .failed, .canceled]

    var isInQueue: Bool {
        Self.queueStatuses.contains(self)
    }

    var isInHistory: Bool {
        Self.historyStatuses.contains(self)
    }

    var isWaiting: Bool {
        [.waitingConfirmation, .waitingExecution].contains(self)
    }

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
