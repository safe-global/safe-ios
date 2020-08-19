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

    init(safe: Safe) {
        model = TransactionsViewModel(safe: safe)
    }

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
                        // avoid reloading details on app open in order to
                        // avoid crashing. The crash is caused by using
                        // the "List" in this detail screen. When
                        // details is reloading and user taps back, the
                        // list somehow gets overreleased and the  app crashes
                        NavigationLink(destination: LoadableView(TransactionDetailsView(transaction: transaction), reloadsOnAppOpen: false)) {
                            TransactionCellView(transaction: transaction)
                        }.onAppear {
                            if self.model.isLast(transaction: transaction) && self.model.canLoadNext {
                                self.model.loadNextPage()
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: Spacing.medium))
                }
            }

            if model.isLoadingNextPage {
                ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
