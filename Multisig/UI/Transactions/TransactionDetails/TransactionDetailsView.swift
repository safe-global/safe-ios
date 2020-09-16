//
//  TransactionDetailsView.swift
//  Multisig
//
//  Created by Moaaz on 5/29/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionDetailsView: View {
    @FetchRequest(fetchRequest: AppSettings.fetchRequest().all())
    private var appSettings: FetchedResults<AppSettings>

    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    private var selectedSafe: FetchedResults<Safe>

    private var safe: Safe { selectedSafe.first! }
    private var safeOwners: [Address] { safe.owners ?? [] }

    @ObservedObject
    var model: TransactionDetailsViewModel

    init(transaction: TransactionViewModel) {
        model = TransactionDetailsViewModel(transaction: transaction)
    }

    private var signingKeyAddress: String? {
        return appSettings.first?.signingKeyAddress
    }

    var body: some View {
        ZStack {
            LoadableView(TransactionDetailsBodyView(model: model, safe: safe), reloadsOnAppOpen: false)

            if model.transaction!.status == .waitingConfirmation &&
                signingKeyAddress != nil &&
                safeOwners.contains(Address(exactly: signingKeyAddress!)) {
                confirmButtonView
            }
        }
        .navigationBarTitle("Transaction Details", displayMode: .inline)
        .background(Color.gnoWhite)
        .onAppear {
            self.trackEvent(.transactionsDetails)
        }
    }

    private var confirmButtonView: some View {
        VStack {
            Spacer()

            Button(action: {
                self.confirmTransaction()
            }) {
                Text("Confirm")
            }
            .buttonStyle(GNOFilledButtonStyle())
            .padding()
        }
    }

    private func confirmTransaction() {
        print("Confirm")
    }
}

fileprivate struct TransactionDetailsBodyView: Loadable {
    let model: TransactionDetailsViewModel
    let safe: Safe

    private var transaction: TransactionViewModel {
        model.transaction!
    }

    @State
    private var showsLink: Bool = false
    private let padding: CGFloat = 11

    var body: some View {
        List {
            if transaction as? CreationTransactionViewModel == nil {
                detailsBodyView
            } else {
                CreationTransactionBodyView(transaction: transaction as! CreationTransactionViewModel)
            }

            if transaction.hash != nil {
                viewTxOnEtherscan
            }
        }
    }

    private var detailsBodyView: some View {
        Group {
            TransactionHeaderView(transaction: transaction)

            if dataDecoded != nil {
                TransactionActionView(dataDecoded: dataDecoded!)
            }

            if data != nil {
                VStack (alignment: .leading) {
                    Text("Data").headline()
                    ExpandableButton(title: "\(data!.length) Bytes", value: data!.data)
                }.padding(.vertical, padding)
            }

            TransactionStatusTypeView(transaction: transaction)
            if displayConfirmations {
                TransactionConfirmationsView(transaction: transaction, safe: safe)
                    .padding(.vertical, padding)
            }

            if transaction.formattedCreatedDate != nil {
                KeyValueRow("Created:",
                            value: transaction.formattedCreatedDate!,
                            enableCopy: false,
                            color: .gnoDarkGrey)
                    .padding(.vertical, padding)
            }

            if transaction.formattedExecutedDate != nil {
                KeyValueRow("Executed:",
                            value: transaction.formattedExecutedDate!,
                            enableCopy: false,
                            color: .gnoDarkGrey)
                    .padding(.vertical, padding)
            }

            if transaction.hasAdvancedDetails {
                NavigationLink(destination: AdvancedTransactionDetailsView(transaction: transaction)) {
                    Text("Advanced").body()
                }
                .frame(height: 48)
            }
        }
    }

    private var viewTxOnEtherscan: some View {
        Button(action: { self.showsLink.toggle() }) {
            LinkText(title: "View transaction on Etherscan")
        }
        .buttonStyle(BorderlessButtonStyle())
        .foregroundColor(.gnoHold)
        .sheet(isPresented: $showsLink, content: browseTransaction)
        .padding(.vertical, padding)
    }

    private func browseTransaction() -> some View {
        return SafariViewController(url: Transaction.browserURL(hash: transaction.hash!))
    }

    private var data: (length: Int, data: String)? {
        guard let customTransaction = transaction as? CustomTransactionViewModel else {
            return nil
        }

        return (length: customTransaction.dataLength, data: customTransaction.data)
    }

    private var dataDecoded: TransactionData? {
        guard let customTransaction = transaction as? CustomTransactionViewModel else {
            return nil
        }

        return customTransaction.dataDecoded
    }

    private var displayConfirmations: Bool {
        guard let transferTransaction = transaction as? TransferTransactionViewModel else {
            return true
        }

        return transferTransaction.isOutgoing
    }
}
