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
    // only in MULTISIG tranasctions
    var transaction: Transaction?

    var data: String?

    // MARK: - Common fields for TransactionSummary
    var nonce: String?

    // MARK: - Transaction Meta Info
    var status: TransactionStatus = .success
    var formattedDate: String = ""
    var date: Date?
    var formattedCreatedDate: String?
    var formattedExecutedDate: String?
    var confirmationCount: UInt64?
    var threshold: UInt64?
    var remainingConfirmationsRequired: UInt64 = 0
    var hash: String?
    var executor: String?
    var signers: [String]?
    var confirmations: [TransactionConfirmationViewModel]?
    var missingSigners: [String]?
    var dataDecoded: DataDecoded?

    var hasConfirmations: Bool {
        confirmationCount ?? 0 > 0
    }

    var browserURL: URL? {
        guard let hash = hash else { return nil }
        return App.configuration.services.etehreumBlockBrowserURL
            .appendingPathComponent("tx").appendingPathComponent(hash)
    }

    static let dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.locale = .autoupdatingCurrent
        d.dateStyle = .medium
        d.timeStyle = .medium
        return d
    }()

    init() {}

    init(_ tx: TransactionSummary) {
        id = tx.id.value
        formattedDate = Self.dateFormatter.string(from: tx.date)
        self.date = tx.date
        
        nonce = tx.executionInfo?.nonce == nil ? "" : "\(tx.executionInfo!.nonce)"

        let confirmationCount = tx.executionInfo?.confirmationsSubmitted ?? 0
        let requiredCount = tx.executionInfo?.confirmationsRequired ?? 0
        let remainingCount = confirmationCount > requiredCount ? 0 : requiredCount - confirmationCount

        self.confirmationCount = confirmationCount
        threshold = requiredCount
        remainingConfirmationsRequired = remainingCount
        missingSigners = tx.executionInfo?.missingSigners?.map { $0.address.checksummed }

        bind(status: tx.txStatus, missingSigners: missingSigners ?? [])
        bind(info: tx.txInfo)
    }

    init(_ tx: TransactionDetails) {
        hash = tx.txHash?.description

        if let multiSigTxInfo = tx.detailedExecutionInfo as? MultisigExecutionDetails {
            let txData = tx.txData!
            transaction = Transaction(txData: txData, multiSigTxInfo: multiSigTxInfo)
            nonce = "\(multiSigTxInfo.nonce)"
            formattedCreatedDate = Self.dateFormatter.string(from: multiSigTxInfo.submittedAt)
            confirmations = multiSigTxInfo.confirmations.map { TransactionConfirmationViewModel(confirmation:$0) }
            executor = multiSigTxInfo.executor?.description
            threshold = multiSigTxInfo.confirmationsRequired
            signers = multiSigTxInfo.signers.map { $0.address.checksummed }
            confirmationCount = UInt64(multiSigTxInfo.confirmations.count)
            remainingConfirmationsRequired = confirmationCount! > threshold! ? 0 : threshold! - confirmationCount!
            
        } else {
            // Module Transaction, we do nothing so far
        }
        
        formattedExecutedDate = tx.executedAt.map { Self.dateFormatter.string(from: $0) }
        formattedDate = formattedExecutedDate ?? formattedCreatedDate ?? ""

        if let txData = tx.txData {
            dataDecoded = txData.dataDecoded
            data = txData.hexData?.description
        }

        bind(status: tx.txStatus, confirmations: confirmations ?? [], signers: signers ?? [])
        bind(info: tx.txInfo)
    }

    convenience init (_ tx: SCGTransaction) {
        if let transactionSummary = tx as? TransactionSummary {
            self.init(transactionSummary)
        } else {
            let transactionDetails = tx as! TransactionDetails
            self.init(transactionDetails)
        }
    }

    func bind(info: TransactionInfo) { }

    func bind(status: TransactionStatus,
              confirmations: [TransactionConfirmationViewModel] = [],
              signers: [String] = [],
              missingSigners: [String] = []) {
        self.status = status
        if status == .awaitingConfirmations {
            guard let signingKeyAddress = App.shared.settings.signingKeyAddress else { return }
            if (signers.contains(signingKeyAddress) &&
                !confirmations.map({ $0.address }).contains(signingKeyAddress)) ||
                missingSigners.contains(signingKeyAddress) {
                self.status = .awaitingYourConfirmation
            }
        }
    }

    static func == (lhs: TransactionViewModel, rhs: TransactionViewModel) -> Bool {
        lhs.id == rhs.id
    }

    class func viewModels(from tx: SCGTransaction) -> [TransactionViewModel] {
        []
    }

    var hasAdvancedDetails: Bool {
        // hash can be for incoming transaction
        nonce != nil || hash != nil
    }
}

protocol TransferAmmountViewModel {
    var isOutgoing: Bool { get set }
    var amount: String { get set }
    var tokenSymbol: String { get set }
    var tokenLogoURL: String { get set }

    var formattedAmount: String { get }
}

extension TransferAmmountViewModel {
    var formattedAmount: String {
        [amount, tokenSymbol].joined(separator: " ")
    }
}
