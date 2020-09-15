//
//  TransactionSummaryViewModel.swift
//  Multisig
//
//  Created by Moaaz on 8/27/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class TransactionViewModel: Identifiable, Equatable {
    var id: String = ""
    var nonce: String?
    var status: SCGTransactionStatus = .success
    var formattedDate: String = ""
    var formattedCreatedDate: String?
    var formattedExecutedDate: String?
    var confirmationCount: UInt64?
    var threshold: UInt64?
    var remainingConfirmationsRequired: UInt64 = 0
    var hash: String?
    var safeHash: String?
    var executor: String?
    var operation: String?
    var confirmations: [TransactionConfirmationViewModel]?
    var dataDecoded: DataDecoded?
    var data: String?

    var hasConfirmations: Bool {
        confirmationCount ?? 0 > 0
    }

    static let dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.locale = .autoupdatingCurrent
        d.dateStyle = .medium
        d.timeStyle = .medium
        return d
    }()

    init() { }

    init(_ tx: TransactionSummary) {
        id = tx.id.value
        formattedDate = Self.dateFormatter.string(from: tx.date)

        nonce = tx.executionInfo?.nonce == nil ? "" : "\(tx.executionInfo!.nonce)"

        do {
            let confirmationCount = tx.executionInfo?.confirmationsSubmitted ?? 0
            let requiredCount = tx.executionInfo?.confirmationsRequired ?? 0
            let remainingCount = confirmationCount > requiredCount ? 0 : requiredCount - confirmationCount

            self.confirmationCount = confirmationCount
            threshold = requiredCount
            remainingConfirmationsRequired = remainingCount
        }

        bind(status: tx.txStatus)
        bind(info: tx.txInfo)
    }

    init(_ tx: TransactionDetails) {
        hash = tx.txHash?.description
        if let multiSigTxInfo = tx.detailedExecutionInfo as? MultisigExecutionDetails {
            nonce = "\(multiSigTxInfo.nonce)"
            formattedCreatedDate = Self.dateFormatter.string(from: multiSigTxInfo.submittedAt)
            confirmations = multiSigTxInfo.confirmations.map { TransactionConfirmationViewModel(confirmation:$0) }
            safeHash = multiSigTxInfo.safeTxHash.description
            threshold = multiSigTxInfo.confirmationsRequired
            confirmationCount = UInt64(multiSigTxInfo.confirmations.count)
            remainingConfirmationsRequired = confirmationCount! > threshold! ? 0 : threshold! - confirmationCount!
        } else {
            // Module Transaction, we do nothing so far
        }
        
        formattedExecutedDate = tx.executedAt.map { Self.dateFormatter.string(from: $0) }
        formattedDate = formattedExecutedDate ?? formattedCreatedDate ?? ""

        if let txData = tx.txData {
            operation = txData.operation.name
            dataDecoded = txData.dataDecoded
            data = txData.hexData?.description
        }

        bind(status: tx.txStatus)
        bind(info: tx.txInfo)
    }

    func bind(info: TransactionInfo) { }

    func bind(status: SCGTransactionStatus) {
        self.status = status
    }

    static func == (lhs: TransactionViewModel, rhs: TransactionViewModel) -> Bool {
        lhs.id == rhs.id
    }

    class func viewModels(from tx: TransactionSummary) -> [TransactionViewModel] {
        []
    }

    class func viewModels(from tx: TransactionDetails) -> [TransactionViewModel] {
        []
    }
}

protocol TransferAmmountViewModel {
    var isOutgoing: Bool { get set }
    var amount: String { get set }
    var tokenSymbol: String { get set }
    var tokenLogoURL: String { get set }
}
