//
//  TransactionDetailsView+AdvancedView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension TransactionDetailsView {

    struct AdvancedView: View {
        let transaction: TransactionViewModel

        static let height: CGFloat = 48

        @ViewBuilder var body: some View {
            if transaction.hasAdvancedDetails {
                NavigationLink(destination: AdvancedTransactionDetailsView(transaction: transaction)) {
                    BodyText("Advanced")
                }
                .frame(height: Self.height)
            } else {
                EmptyView()
            }
        }
    }
}
