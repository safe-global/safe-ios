//
//  AdvancedTransactionDetailsView.swift
//  Multisig
//
//  Created by Moaaz on 5/29/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AdvancedTransactionDetailsView: View {
    @ObservedObject
    var theme: Theme = App.shared.theme
    
    let transactionViewModel: TransactionViewModel
    private let padding: CGFloat = 11

    var transaction: Transaction? { return transactionViewModel.transaction }

    var body: some View {
        List {
            if transactionViewModel.nonce != nil {
                KeyValueRow("Nonce:", value: transactionViewModel.nonce!, enableCopy: true, color: .gnoDarkGrey)
                    .padding(.vertical, padding)
            }

            if transaction != nil {
                KeyValueRow(
                    "Type of operation:", value: transaction!.operation.name, enableCopy: true, color: .gnoDarkGrey
                ).padding(.vertical, padding)
            }

            if transactionViewModel.hash != nil {
                KeyValueRow(
                    "Transaction hash:", value: transactionViewModel.hash!, enableCopy: true, color: .gnoDarkGrey
                ).padding(.vertical, padding)
            }
        }
        .navigationBarTitle("Advanced", displayMode: .inline)
        .onAppear {
            self.trackEvent(.transactionsDetailsAdvanced)
        }
    }
}
