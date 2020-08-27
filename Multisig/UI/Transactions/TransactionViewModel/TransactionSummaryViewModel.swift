//
//  TransactionSummaryViewModel.swift
//  Multisig
//
//  Created by Moaaz on 8/27/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionSummaryViewModel: Identifiable, Equatable {
    let id: UUID
    var nonce: String?
    var status: SCGTransactionStatus
    var date: Date?
    var formattedCreatedDate: String?
    var formattedExecutedDate: String?
    var formattedDate: String
    var confirmationCount: UInt64?
    var threshold: UInt64?
    
    static let dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.locale = .autoupdatingCurrent
        d.dateStyle = .medium
        d.timeStyle = .medium
        return d
    }()

    init(_ tx: TransactionSummary, _ safe: SafeStatusRequest.Response) {
        id = UUID()
        date = tx.date

        formattedDate = date.map { Self.dateFormatter.string(from: $0) } ?? ""

        status = tx.txStatus
        nonce = tx.executionInfo?.nonce == nil ? "" : "\(tx.executionInfo?.nonce)"

        confirmationCount = tx.executionInfo?.confirmationsSubmitted
        threshold = tx.executionInfo?.confirmationsRequired
    }
}
