//
//  TransferValueView.swift
//  Multisig
//
//  Created by Moaaz on 6/16/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransferValueView: View {
    let transaction: TransferTransactionViewModel

    private let dimension: CGFloat = 36

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if transaction.tokenSymbol == App.shared.tokenRegistry.token(address: .ether)?.symbol {
                TokenImage.ether.frame(width: dimension, height: dimension)
            } else if logoURL != nil  {
                TokenImage(url: logoURL).frame(width: dimension, height: dimension)
            } else {
                TokenImage.placeholder.frame(width: dimension, height: dimension)
            }

            VStack (alignment: .leading) {
                Text("\(transaction.amount) \(transaction.tokenSymbol)")
                    .body(amountColor)
                if dataLength != 0 {
                    Text("\(dataLength) bytes")
                        .footnote()
                }
            }.opacity(opactiy)
        }
    }

    var logoURL: URL? {
        URL(string: transaction.tokenLogoURL)
    }

    var amountColor: Color {
        return transaction.isOutgoing ? .gnoDarkBlue : .gnoHold
    }

    var opactiy: Double {
        [.cancelled, .failed].contains(transaction.status) ? 0.5 : 1
    }

    var dataLength: Int {
        return (transaction as? CustomTransactionViewModel)?.dataLength ?? 0
    }
}

struct TransferValueView_Previews: PreviewProvider {
    static var previews: some View {
        let transaction = TransferTransactionViewModel()
        transaction.address = "0x71592E6Cbe7779D480C1D029e70904041F8f602A"
        transaction.confirmationCount = 1
        transaction.threshold = 2
        transaction.formattedDate = "Apr 25, 2020 — 1:01:42PM"
        transaction.nonce = "2"
        transaction.amount = "5"
        transaction.tokenSymbol = " ETH"
        transaction.isOutgoing = true
        transaction.status = .success

        return TransferValueView(transaction: transaction)
    }
}
