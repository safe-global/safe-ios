//
//  TransferCellContent.swift
//  Multisig
//
//  Created by Moaaz on 6/4/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransferCellContent: View {
    let transaction: TransferTransactionViewModel
    var body: some View {
        HStack (alignment: .center) {
            Image(imageName)
            AddressCell(address: transaction.address,
                        style: .shortAddressNoShare)

            Spacer()

            BodyText("\(transaction.amount) \(transaction.tokenSymbol)",
                textColor: amountColor)
        }
    }

    var imageName: String {
        return transaction.isOutgoing ? "ico-outgoing-tx" : "ico-incoming-tx"
    }

    var amountColor: Color {
        return transaction.isOutgoing ? .gnoDarkBlue : .gnoHold
    }
}



struct TransferCellContent_Previews: PreviewProvider {
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

        return TransferCellContent(transaction: transaction)
    }
}
