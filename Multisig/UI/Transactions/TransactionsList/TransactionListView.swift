//
//  TransactionListView.swift
//  Multisig
//
//  Created by Moaaz on 5/29/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionListView: Loadable {
    @ObservedObject
    var model: TransactionsViewModel

    var body: some View {
        ZStack {
            if model.transactionsList.isEmpty {
                EmptyListPlaceholder(label: "Transactions will appear here", image: "ico-no-transactions")
            } else {
                transactionsList
            }
        }
        .onAppear {
            self.trackEvent(.transactions)
        }
    }

    var transactionsList: some View {
        List {
            ForEach(model.transactionsList.sections) { section in
                Section(header: SectionHeader(section.name)) {
                    ForEach(section.transactions) { transaction in
                        NavigationLink(destination: TransactionDetailsView(transaction: transaction)) {
                            TransactionCellView(transaction: transaction)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                }
            }
        }
    }
}
