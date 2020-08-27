//
//  TransactionStatus+ViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 17.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension SCGTransactionStatus {

    static let queueStatuses = [SCGTransactionStatus.awaitingConfirmations, .awaitingExecution]
    static let historyStatuses = [SCGTransactionStatus.success, .failed, .cancelled]

    var isInQueue: Bool {
        Self.queueStatuses.contains(self)
    }

    var isInHistory: Bool {
        Self.historyStatuses.contains(self)
    }

    var isWaiting: Bool {
        [.awaitingConfirmations, .awaitingExecution].contains(self)
    }

    var title: String {
        switch self {
        case .awaitingExecution:
            return "Awaiting execution"
        case .awaitingConfirmations:
            return "Awaiting confirmations"
        case .pending:
             return "Pending"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        case .success:
            return "Success"
        }
    }

}
