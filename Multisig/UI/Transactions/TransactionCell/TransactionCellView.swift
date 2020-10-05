//
//  TransactionCellView.swift
//  Multisig
//
//  Created by Moaaz on 6/4/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionCellView: View {
    let transaction: TransactionViewModel
    var body: some View {
        VStack (alignment: .leading, spacing: 4) {
            contentView.opacity(opacity)

            HStack {
                if transaction.nonce != nil {
                    Text(transaction.nonce!)
                        .footnote()
                        .opacity(opacity)
                }

                Text(transaction.formattedDate)
                    .footnote()
                    .opacity(opacity)

                if !transaction.status.isWaiting  {
                    TransactionStatusView(status: transaction.status, style: .footnote)
                }
            }

            if transaction.status.isWaiting {
                HStack {
                    TransactionStatusView(status: transaction.status, style: .footnote)

                    Spacer()

                    if transaction.threshold != nil {
                        ConfirmationCountView(currentValue: transaction.confirmationCount ?? 0, threshold: transaction.threshold!).opacity(opacity)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            App.shared.theme.resetRowsSelection()
        }
    }

    var contentView: some View {
        let transferTransaction = transaction as? TransferTransactionViewModel
        let settingChangeTransaction = transaction as? SettingChangeTransactionViewModel
        let changeImplementationTransaction = transaction as? ChangeImplementationTransactionViewModel
        let customTransaction = transaction as? CustomTransactionViewModel
        let creationTransaction = transaction as? CreationTransactionViewModel

        return ZStack {
            if customTransaction != nil {
                CustomTransactionCellView(transaction: customTransaction!)
            } else if transferTransaction != nil {
                TransferTransactionCellView(transaction: transferTransaction!)
            } else if settingChangeTransaction != nil {
                SettingsChangeTransactionCellView(transaction: settingChangeTransaction!)
            } else if changeImplementationTransaction != nil {
                ChangeImplementationCellView(transaction: changeImplementationTransaction!)
            } else if creationTransaction != nil {
                CreationTransactionCellView(transaction: creationTransaction!)
            } else {
                EmptyView()
            }
        }
    }

    var opacity: Double {
        switch transaction.status {
        case .awaitingExecution, .awaitingConfirmations, .awaitingYourConfirmation, .pending, .success:
             return 1
        case .failed, .cancelled:
            return 0.5
        }
    }
}
