//
//  TransactionDetailsView.swift
//  Multisig
//
//  Created by Moaaz on 5/29/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionDetailsView: View {

    static let verticalContentPadding: CGFloat = 11

    let transaction: TransactionViewModel

    var body: some View {
        List {
            HeaderView(transaction: transaction)
            DataView(transaction: transaction)
            TypeView(transaction: transaction)
            ConfirmationsView(transaction: transaction)
            CreatedDateView(transaction: transaction)
            ExecutedDateView(transaction: transaction)
            AdvancedView(transaction: transaction)
            BrowseView(transaction: transaction)
        }
        .navigationBarTitle("Transaction Details", displayMode: .inline)
        .onAppear {
            self.trackEvent(.transactionsDetails)
        }
    }

}
