//
//  TransactionSummaryViewModel.swift
//  Multisig
//
//  Created by Moaaz on 8/27/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionSummaryViewModelCopy: Identifiable, Equatable {
    let id: UUID
    var nonce: String?
    var executor: String?
    var status: SCGTransactionStatus
    var date: Date?
    var formattedCreatedDate: String?
    var formattedExecutedDate: String?
    var formattedDate: String
    var operation: String?
    var confirmationCount: Int?
    var threshold: Int?
    var confirmations: [TransactionConfirmationViewModel]?
    var remainingConfirmationsRequired: Int
    var hasConfirmations: Bool {
        confirmations.map { !$0.isEmpty } ?? false
    }

    static let dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.locale = .autoupdatingCurrent
        d.dateStyle = .medium
        d.timeStyle = .medium
        return d
    }()

    init(_ tx: TransactionSummary, _ safe: SafeStatusRequest.Response) {
        date = tx.executionDate ?? tx.submissionDate ?? tx.modified
        formattedCreatedDate = tx.submissionDate.map { Self.dateFormatter.string(from: $0) }
        formattedExecutedDate = tx.executionDate.map { Self.dateFormatter.string(from: $0) }
        formattedDate = date.map { Self.dateFormatter.string(from: $0) } ?? ""
        operation = tx.operation?.name
        confirmations = tx.confirmations.map { $0.map(TransactionConfirmationViewModel.init(confirmation:)) }
        // computing confirmation counters
        do {
            let confirmationCount = confirmations?.count ?? 0
            let requiredCount = Int(clamping: tx.confirmationsRequired?.value ?? safe.threshold.value)
            let remainingCount = max(requiredCount - confirmationCount, 0)

            self.confirmationCount = confirmationCount
            self.threshold = requiredCount
            remainingConfirmationsRequired = remainingCount
        }
        status = tx.status(safeNonce: safe.nonce.value,
                           safeThreshold: safe.threshold.value)
        nonce = tx.nonce.map { String($0.value) }

        executor = tx.executor?.address.checksummed
    }
}

extension TransactionSummaryViewModel {

    static func create(from tx: TransactionSummary, _ info: SafeStatusRequest.Response) -> [TransactionSummaryViewModel] {
        // ask each class to create view models
        // and take the first recognized result
        [
            TransferTransactionViewModel.self,
            SettingChangeTransactionViewModel.self,
            ChangeImplementationTransactionViewModel.self,
            CustomTransactionViewModel.self
        ]
        .map { $0.viewModels(from: tx, info: info) }
        .first { !$0.isEmpty }
        ?? []
    }

}
