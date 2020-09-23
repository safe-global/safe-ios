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

    var transactionDetails: TransactionViewModel {
        model.transactionDetails
    }

    init(transaction: TransactionViewModel) {
        model = TransactionDetailsViewModel(transaction: transaction)
    }

    @State
    private var showsLink: Bool = false
    private let padding: CGFloat = 11

    var body: some View {
        List {
            if transactionDetails is CreationTransactionViewModel {
                CreationTransactionBodyView(transaction: transactionDetails as! CreationTransactionViewModel)
            } else {
                transactionDetailsBodyView
            }
            
            if transactionDetails.browserURL != nil {
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
            TransactionHeaderView(transaction: transactionDetails)

            if dataDecoded != nil {
                TransactionActionView(dataDecoded: dataDecoded!)
            }

            if data != nil {
                VStack (alignment: .leading) {
                    Text("Data").headline()
                    ExpandableButton(title: "\(data!.length) Bytes", value: data!.data)
                }.padding(.vertical, 11)
            }

            TransactionStatusTypeView(transaction: transactionDetails)
            if displayConfirmations {
                TransactionConfirmationsView(transaction: transactionDetails, safe: selectedSafe.first!).padding(.vertical, padding)
            }

            if transactionDetails.formattedCreatedDate != nil {
                KeyValueRow("Created:", value: transactionDetails.formattedCreatedDate!, enableCopy: false, color: .gnoDarkGrey).padding(.vertical, padding)
            }

            if transactionDetails.formattedExecutedDate != nil {
                KeyValueRow("Executed:", value: transactionDetails.formattedExecutedDate!, enableCopy: false, color: .gnoDarkGrey).padding(.vertical, padding)
            }

            if transactionDetails.hasAdvancedDetails {
                NavigationLink(destination: AdvancedTransactionDetailsView(transaction: transactionDetails)) {
                    Text("Advanced").body()
                }
                .frame(height: 48)
            }
        }
    }

    func browseTransaction() -> some View {
        SafariViewController(url: transactionDetails.browserURL!)
    }

    var data: (length: UInt256, data: String)? {
        guard let customTransaction = transactionDetails as? CustomTransactionViewModel, let data = customTransaction.data else {
            return nil
        }

        return (length: customTransaction.dataLength, data: data)
    }

    var dataDecoded: DataDecoded? {
        guard let customTransaction = transactionDetails as? CustomTransactionViewModel else {
            return nil
        }

        return customTransaction.dataDecoded
    }

    var displayConfirmations: Bool {
        guard let transferTransaction = transactionDetails as? TransferTransactionViewModel else {
            return true
        }

        return transferTransaction.isOutgoing
    }
}
