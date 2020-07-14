//
//  BrowseView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension TransactionDetailsView {

    struct BrowseView: View {

        @State private var showsLink: Bool = false

        let transaction: TransactionViewModel

        @ViewBuilder var body: some View {
            if transaction.hash != nil {
                Button(action: { self.showsLink.toggle() }) {
                    LinkText(title: "View transaction on Etherscan")
                }
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(.gnoHold)
                .sheet(isPresented: $showsLink, content: browseTransaction)
                .padding(.vertical, TransactionDetailsView.verticalContentPadding)
            } else {
                EmptyView()
            }
        }

        private func browseTransaction() -> some View {
             SafariViewController(url: Transaction.browserURL(hash: transaction.hash!))
        }
    }

}
