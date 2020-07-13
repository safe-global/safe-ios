//
//  TransactionDetailsView+ExecutedDateView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension TransactionDetailsView {

    struct ExecutedDateView: View {
        let transaction: TransactionViewModel

        @ViewBuilder var body: some View {
            if transaction.formattedExecutedDate != nil {
                KeyValueRow("Created:",
                            value: transaction.formattedExecutedDate!,
                            enableCopy: false,
                            color: .gnoDarkGrey)
                    .padding(.vertical, TransactionDetailsView.verticalContentPadding)
            } else {
                EmptyView()
            }
        }
    }

}
