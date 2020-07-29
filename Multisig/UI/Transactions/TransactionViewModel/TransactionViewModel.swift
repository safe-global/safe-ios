//
//  TransactionViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class TransactionViewModel: Identifiable, Equatable {

    let id: UUID
    var nonce: String?
    var hash: String?
    var safeHash: String?
    var executor: String?
    var status: TransactionStatus
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

    init() {
        id = UUID()
        status = .success
        formattedDate = ""
        confirmations = []
        remainingConfirmationsRequired = 0
    }

    init(_ tx: Transaction, _ safe: SafeStatusRequest.Response) {
        id = UUID()
        hash = tx.transactionHash?.description
        safeHash = tx.safeTxHash?.description
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

    static func == (lhs: TransactionViewModel, rhs: TransactionViewModel) -> Bool {
        lhs.id == rhs.id
    }

    class func viewModels(from tx: Transaction, info: SafeStatusRequest.Response) -> [TransactionViewModel] {
        []
    }

}

extension GnosisSafeOperation {
    var name: String {
        switch self {
        case .call:
            return "call"
        case .delegateCall:
            return "delegateCall"
        }
    }
}
