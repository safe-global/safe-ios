//
//  BaseTransactionViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class BaseTransactionViewModel {

    var nonce: String?
    var status: TransactionStatus
    var date: Date?
    var formattedDate: String
    var confirmationCount: Int?
    var threshold: Int?

    static let dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.locale = .autoupdatingCurrent
        d.dateStyle = .medium
        d.timeStyle = .medium
        return d
    }()

    init() {
        status = .success
        formattedDate = ""
    }

    init(_ tx: Transaction, _ safe: SafeStatusRequest.Response) {
        date = tx.executionDate ?? tx.submissionDate ?? tx.modified
        formattedDate = date.map { Self.dateFormatter.string(from: $0) } ?? ""
        confirmationCount = tx.confirmations.map { $0.count }
        threshold = tx.confirmationsRequired.map { Int(clamping: $0.value) }
        status = tx.status(safeNonce: safe.nonce.value,
                           safeThreshold: safe.threshold.value)
        nonce = tx.nonce.map { String($0.value) }
    }

}
