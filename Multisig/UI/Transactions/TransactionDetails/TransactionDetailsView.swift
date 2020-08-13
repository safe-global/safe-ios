//
//  TransactionDetailsView.swift
//  Multisig
//
//  Created by Moaaz on 5/29/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionDetailsView: Loadable {
    @ObservedObject
    var model: TransactionDetailsViewModel
    
    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selectedSafe: FetchedResults<Safe>

    var transaction: TransactionViewModel {
        model.transaction!
    }

    init(transaction: TransactionViewModel) {
        model = TransactionDetailsViewModel(transaction: transaction)
    }

    init(hash: String) {
        model = TransactionDetailsViewModel(hash: hash)
    }

    @State
    private var showsLink: Bool = false
    private let padding: CGFloat = 11

    var body: some View {
        List {
            if transaction as? CreationTransactionViewModel == nil {
                transactionDetailsBodyView
            } else {
                CreationTransactionBodyView(transaction: transaction as! CreationTransactionViewModel)
            }
            
            if transaction.hash != nil {
                Button(action: { self.showsLink.toggle() }) {
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

    var transactionDetailsBodyView: some View {
        Group {
            TransactionHeaderView(transaction: transaction)

            if data != nil {
                VStack (alignment: .leading) {
                    Text("Data").headline()
                    ExpandableButton(title: "\(data!.length) Bytes", value: data!.data)
                }.padding(.vertical, 11)
            }

            TransactionStatusTypeView(transaction: transaction)
            if displayConfirmations {
                TransactionConfirmationsView(transaction: transaction, safe: selectedSafe.first!).padding(.vertical, padding)
            }

            if transaction.formattedCreatedDate != nil {
                KeyValueRow("Created:", value: transaction.formattedCreatedDate!, enableCopy: false, color: .gnoDarkGrey).padding(.vertical, padding)
            }

            if transaction.formattedExecutedDate != nil {
                KeyValueRow("Executed:", value: transaction.formattedExecutedDate!, enableCopy: false, color: .gnoDarkGrey).padding(.vertical, padding)
            }

            if transaction.hasAdvancedDetails {
                NavigationLink(destination: AdvancedTransactionDetailsView(transaction: transaction)) {
                    Text("Advanced").body()
                }
                .frame(height: 48)
            }
        }
    }

    func browseTransaction() -> some View {
        return SafariViewController(url: Transaction.browserURL(hash: transaction.hash!))
    }

    var data: (length: Int, data: String)? {
        guard let customTransaction = transaction as? CustomTransactionViewModel else {
            return nil
        }

        return (length: customTransaction.dataLength, data: customTransaction.data)
    }

    var displayConfirmations: Bool {
        guard let transferTransaction = transaction as? TransferTransactionViewModel else {
            return true
        }

        return transferTransaction.isOutgoing
    }
}
