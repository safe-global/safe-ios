//
//  TransactionsContentView.swift
//  Multisig
//
//  Created by Moaaz on 5/29/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionsContentView: View {
    @ObservedObject
    var model: TransactionsViewModel

    init(_ safe: Safe) {
        model = TransactionsViewModel(safe: safe)
    }
    
    var body: some View {
        ZStack {
            if model.isLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
            } else if model.errorMessage != nil {
                ErrorText(model.errorMessage!)
            } else if model.transactionsList.isEmpty {
                EmptyListPlaceholder(label: "Transactions will appear here", image: "ico-no-transactions")
            } else {
                transactionsList
            }
        }
    }

    var transactionsList: some View {
        EmptyView()
//        List {
//            if !model.transactionsList.queuedTransactions.isEmpty {
//                Section(header: SectionHeader("QUEUE")) {
//                    ForEach(model.transactionsList.queuedTransactions) { transaction in
//                        NavigationLink(destination: TransactionDetailsView(transaction: transaction)) {
//                            TransactionCellView(transaction: transaction)
//                        }
//                    }
//                }
//            }
//
//            if !model.transactionsList.isEmpty {
//                Section(header: SectionHeader("HISTORY")) {
//                    ForEach(model.transactionsList.historyTransactions) { transaction in
//                        NavigationLink(destination: TransactionDetailsView(transaction: transaction)) {
//                            TransactionCellView(transaction: transaction)
//                        }
//                    }
//                }
//            }
//        }
    }
}

//struct TransactionsContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionsContentView()
//    }
//}
