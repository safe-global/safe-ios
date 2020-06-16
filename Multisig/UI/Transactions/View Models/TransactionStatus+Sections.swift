//
//  TransactionStatus+Sections.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
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
}
