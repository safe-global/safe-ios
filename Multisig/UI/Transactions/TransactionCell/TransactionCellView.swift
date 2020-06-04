//
//  TransactionCellView.swift
//  Multisig
//
//  Created by Moaaz on 6/4/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionCellView: View {
    let transaction: BaseTransactionViewModel
    var body: some View {
        VStack (alignment: .leading, spacing: 4){
            contentView.opacity(opacity)

            HStack{
                if transaction.nonce != nil {
                    FootnoteText(transaction.nonce!, color: .gnoDarkGrey).opacity(opacity)
                }

                FootnoteText(transaction.formattedDate, color: .gnoDarkGrey).opacity(opacity)

                if [TransactionStatus.success, TransactionStatus.pending, TransactionStatus.canceled, TransactionStatus.failed].contains(transaction.status)  {
                    FootnoteText(formatedStatusText, color: statusColor)
                }
            }

            if [TransactionStatus.waitingConfirmation, TransactionStatus.waitingExecution].contains(transaction.status) {
                HStack {
                    FootnoteText(formatedStatusText, color: statusColor)

                    Spacer()

                    if transaction.threshold != nil {
                        ConfirmationCountView(currentValue: transaction.confirmationCount ?? 0, threshold: transaction.threshold!).opacity(opacity)
                    }
                }
            }
        }.padding()
    }

    var contentView: some View {
        let transferTransaction = transaction as? TransferTransaction
        let settingChangeTransaction = transaction as? SettingChangeTransaction
        let changeMasterCopyTransaction = transaction as? ChangeMasterCopyTransaction
        let customTransaction = transaction as? CustomTransaction

        return ZStack {
            if customTransaction != nil {
                CustomTransactionCellView(transaction: customTransaction!)
            }
            else if transferTransaction != nil {
                TransferTransactionCellView(transaction: transferTransaction!)
            }
            else if settingChangeTransaction != nil {
                SettingsChangeTransactionCellView(transaction: settingChangeTransaction!)
            }
            else if changeMasterCopyTransaction != nil {
                ChangeMasterCopyCellView(transaction: changeMasterCopyTransaction!)
            }
            else {
                EmptyView()
            }
        }
    }

    var formatedStatusText: String {
        let statusTitle = transaction.status.title
        switch transaction.status {
        case .waitingExecution, .waitingConfirmation, .pending:
            return "• " + statusTitle
        case .failed, .canceled, .success:
            return statusTitle
        }
    }

    var statusColor: Color {
        switch transaction.status {
        case .waitingExecution, .waitingConfirmation, .pending:
             return .gnoPending
        case .failed:
            return .gnoTomato
        case .canceled:
            return .gnoDarkGrey
        case .success:
            return .gnoHold
        }
    }

    var opacity: Double {
        switch transaction.status {
        case .waitingExecution, .waitingConfirmation, .pending, .success:
             return 1
        case .failed, .canceled:
            return 0.5
        }
    }
}

struct TransactionCellView_Previews: PreviewProvider {
    static var previews: some View {
        let transaction = ChangeMasterCopyTransaction()
        transaction.contractAddress = "0x71592E6Cbe7779D480C1D029e70904041F8f602A"
        transaction.contractVersion = "1.1.1"
        transaction.confirmationCount = 1
        transaction.threshold = 2
        transaction.formattedDate = "Apr 25, 2020 — 1:01:42PM"
        transaction.nonce = "2"
        transaction.status = .failed

        //disabled mode
        return TransactionCellView(transaction: transaction)
    }
}
