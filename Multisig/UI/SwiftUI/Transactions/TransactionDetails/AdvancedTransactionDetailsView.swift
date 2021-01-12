//
//  AdvancedTransactionDetailsView.swift
//  Multisig
//
//  Created by Moaaz on 5/29/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AdvancedTransactionDetailsView: View {
    var nonce: String?
    var operation: String?
    var hash: String?
    var safeTxHash: String?
    private let padding: CGFloat = 11

    var body: some View {
        List {
            if let nonce = nonce {
                KeyValueRow("Nonce:", value: nonce, enableCopy: true, color: .gnoDarkGrey)
                    .padding(.vertical, padding)
            }

            if let operation = operation {
                KeyValueRow(
                    "Type of operation:", value: operation, enableCopy: true, color: .gnoDarkGrey
                ).padding(.vertical, padding)
            }

            if let hash = hash {
                KeyValueRow(
                    "Transaction hash:", value: hash, enableCopy: true, color: .gnoDarkGrey
                ).padding(.vertical, padding)
            }

            if let safeTxHash = safeTxHash {
                KeyValueRow(
                    "safeTxHash:", value: safeTxHash, enableCopy: true, color: .gnoDarkGrey
                ).padding(.vertical, padding)
            }
        }
        .navigationBarTitle("Advanced", displayMode: .inline)
        .onAppear {
            self.trackEvent(.transactionsDetailsAdvanced)
        }
    }
}
