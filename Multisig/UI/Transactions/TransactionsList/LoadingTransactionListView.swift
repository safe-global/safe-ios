//
//  LoadingTransactionListView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionsTabView: View {
    var body: some View {
        WithSelectedSafe(safeNotSelectedEvent: .transactionsNoSafe) {
            LoadingTransactionListView()
        }
        .navigationBarTitle("Transactions")
    }
}


struct LoadingTransactionListView: View {
    @EnvironmentObject var model: LoadingTransactionListViewModel
    
    var body: some View {
        NetworkContentView(status: model.status, reload: model.reload) {
            TransactionListView(list: model.list,
                                loadMoreStatus: model.loadMoreStatus,
                                reload: model.reload,
                                loadMore: model.loadMore)
        }
        .onAppear {
            trackEvent(.transactions)
        }
    }
}

struct TransactionListView: View {
    var list: TransactionsListViewModel
    var loadMoreStatus: ViewLoadingStatus
    var reload: () -> Void = {}
    var loadMore: () -> Void = {}

    var body: some View {
        List {
            Section {
                ReloadButton(reload: reload)
            }
            ForEach(list.sections) { section in
                Section(header: SectionHeader(section.name)) {
                    ForEach(section.transactions) { transaction in
                        NavigationLink(
                            destination: LoadingTransactionDetailsView(transaction: transaction)) {
                                TransactionCellView(transaction: transaction)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: Spacing.medium))
                }
            }
            if list.next != nil {
                if loadMoreStatus == .loading {
                    ProgressIndicatorCell()
                } else {
                    LoadMoreButton(loadMore: loadMore)
                }
            }
        }
        .listStyle(GroupedListStyle())
    }

}
