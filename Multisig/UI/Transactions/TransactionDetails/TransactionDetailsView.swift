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

    let transaction: TransactionViewModel

    @State
    private var showsLink: Bool = false
    private let padding:CGFloat = 11

    var body: some View {
        List {
            TransactionHeaderView(transaction: transaction)

            if data != nil {
                VStack (alignment: .leading) {
                    BoldText("Data")
                    ExpandableButton(title: "\(data!.0) Bytes", value: data!.1)
                }.padding(.vertical, 11)
            }

            TransactionStatusTypeView(transaction: transaction)
            if !(transaction.confirmations?.isEmpty ?? true) {
                TransactionConfirmationsView(transaction: transaction, safe: selectedSafe.first!).padding(.vertical, padding)
            }

            if transaction.createdDate != nil {
                KeyValueRow("Created", transaction.createdDate!, false, .gnoDarkGrey).padding(.vertical, padding)
            }

            if transaction.executedDate != nil {
                KeyValueRow("Executed", transaction.executedDate!, false, .gnoDarkGrey).padding(.vertical, padding)
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
                .padding(.vertical, padding)
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

    var data: (Int, String)? {
        guard let customTransaction = transaction as? CustomTransactionViewModel else {
            return nil
        }

        return (customTransaction.dataLength, customTransaction.data)
    }
}
