//
//  TransactionCell+StatusView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension TransactionCell {

    struct StatusView: View {

        let transaction: TransactionViewModel
        let opacity: Double

        @ViewBuilder var body: some View {
            HStack {
                if transaction.nonce != nil {
                    FootnoteText(transaction.nonce!, color: .gnoDarkGrey)
                        .opacity(opacity)
                }

                FootnoteText(transaction.formattedDate, color: .gnoDarkGrey)
                    .opacity(opacity)

                if !transaction.status.isWaiting  {
                    TransactionStatusView(status: transaction.status,
                                          style: .footnote)
                }
            }

            if transaction.status.isWaiting {
                HStack {
                    TransactionStatusView(status: transaction.status,
                                          style: .footnote)

                    Spacer()

                    if transaction.threshold != nil {
                        ConfirmationCountView(currentValue: transaction.confirmationCount ?? 0,
                                              threshold: transaction.threshold!)
                            .opacity(opacity)
                    }
                }
            }
        }
    }
}

