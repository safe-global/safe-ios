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
    
    let transaction: TransactionViewModel
    private let padding: CGFloat = 11

    var body: some View {
        List {
            if transaction.nonce != nil {
                KeyValueRow("Nonce", transaction.nonce!, true, .gnoDarkGrey).padding(.vertical, padding)
            }

            if transaction.operation != nil {
                KeyValueRow("Type of operation", transaction.operation!, true, .gnoDarkGrey).padding(.vertical, padding)
            }

            if transaction.hash != nil {
                KeyValueRow("Transaction hash", transaction.hash!, true, .gnoDarkGrey).padding(.vertical, padding)
            }
        }
        .navigationBarTitle("Advanced", displayMode: .inline)
        .onAppear {
            self.theme.setTemporaryTableViewBackground(nil)
            self.trackEvent(.transactionsDetailsAdvanced)
        }
        .onDisappear {
            self.theme.resetTemporaryTableViewBackground()
        }
    }
}

extension TransactionViewModel {
    var hasAdvancedDetails: Bool {
        nonce != nil && operation != nil && hash != nil
    }
}
