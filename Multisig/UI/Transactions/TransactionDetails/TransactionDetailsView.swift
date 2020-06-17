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

    @State
    private var showsLink: Bool = false
    
    var body: some View {
        List {
            TransactionHeaderView(transaction: transaction)
            TransactionStatusTypeView(transaction: transaction)
            if !(transaction.confirmations?.isEmpty ?? true) {
                TransactionConfirmationsView(transaction: transaction, safe: selectedSafe.first!)
            }

            if transaction.createdDate != nil {
                KeyValueRow("Created", transaction.createdDate!)
            }

            if transaction.executedDate != nil {
                KeyValueRow("Executed", transaction.executedDate!)
            }
            
            NavigationLink(destination: AdvancedTransactionDetailsView(transaction: transaction)) {
                BodyText("Advanced")
            }
            .frame(height: 48)

            if transaction.hash != nil {
                Button(action: { self.showsLink.toggle()}) {
                    LinkText(title: "View transaction on Etherscan")
                }
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(.gnoHold)
                .sheet(isPresented: $showsLink, content: browseTransaction)
            }
        }
        .navigationBarTitle("Transaction Details", displayMode: .inline)
        .onAppear {
            self.trackEvent(.transactionsDetails)
        }
    }

    func browseTransaction() -> some View {
        return SafariViewController(url: Transaction.browserURL(hash: transaction.hash!))
    }
}
