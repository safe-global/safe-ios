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
        .onAppear {
            self.trackEvent(.transactions)
        }
    }

    var transactionsList: some View {
        List {
            ForEach(model.transactionsList.sections, id: \.name) { section in
                Section(header: SectionHeader(section.name)) {
                    ForEach(section.transactions, id: \.nonce) { transaction in
                        TransactionCellView(transaction: transaction)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                }
            }
        }
    }
}

//struct TransactionsContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionsContentView()
//    }
//}
