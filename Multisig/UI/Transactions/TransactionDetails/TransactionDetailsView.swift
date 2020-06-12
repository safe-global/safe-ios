//
//  TransactionDetailsView.swift
//  Multisig
//
//  Created by Moaaz on 5/29/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionDetailsView: View {
    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selectedSafe: FetchedResults<Safe>

    let transaction: BaseTransactionViewModel
    var body: some View {
        List {
            TransactionHeaderView(transaction: transaction)
            if !(transaction.confirmations?.isEmpty ?? true) {
                TransactionConfirmationsView(transaction: transaction, safe: selectedSafe.first!)
            }
            
            NavigationLink(destination: AdvancedTransactionDetailsView(transaction: transaction)) {
                BodyText("Advanced")
            }
            .frame(height: 48)
        }.navigationBarTitle("Transaction Details", displayMode: .inline)
    }
}
