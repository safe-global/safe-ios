//
//  ConfirmationsView.swift
//  Multisig
//
//  Created by Moaaz on 6/10/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension TransactionDetailsView {

    struct ConfirmationsView: View {
        let transaction: TransactionViewModel

        @ViewBuilder var body: some View {
            if displayConfirmations {

                VStack(alignment: .leading, spacing: 1) {
                    TransactionConfiramtionStatusView(style: .created)
                    VerticalBarView()

                    ForEach(transaction.confirmations ?? [], id: \.address) { confirmation in
                        TransactionConfirmationCell(address: confirmation.address, style: .confirmed)
                    }

                    if transaction.status == .success {
                        if transaction.executor != nil {
                            TransactionConfirmationCell(address: transaction.executor!, style: .executed)
                        } else {
                            TransactionConfiramtionStatusView(style: .executed)
                        }
                    } else {
                        actionsView
                    }
                }
                .padding(.vertical, TransactionDetailsView.verticalContentPadding)
            } else {
                EmptyView()
            }
        }

        var displayConfirmations: Bool {
            guard let transferTransaction = transaction as? TransferTransactionViewModel else {
                return true
            }

            return transferTransaction.isOutgoing
        }

        var actionsView: some View {
            VStack (alignment: .leading, spacing: 1) {
                if style != nil {
                    TransactionConfiramtionStatusView(style: style!)
                }

                if transaction.status == .waitingConfirmation {
                    if !transaction.hasConfirmations {
                        VerticalBarView()
                    }

                    TransactionConfiramtionStatusView(style: .waitingConfirmations(transaction.remainingConfirmationsRequired))
                }
            }.fixedSize()
        }

        var style: TransactionConfiramtionStatusViewStyle? {
            let status = transaction.status
            if transaction.status == .cancelled {
                return .cancelled
            } else if transaction.status == .failed {
                return .failed
            } else if status == .waitingConfirmation {
                return transaction.hasConfirmations ? nil : .confirm
            } else if status == .waitingExecution {
                return .execute
            }

            return nil
        }
    }

}
