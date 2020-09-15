//
//  TransferTransactionHeaderView.swift
//  Multisig
//
//  Created by Moaaz on 6/16/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CustomTransactionDetailsHeaderView: View {
    let transaction: CustomTransactionViewModel

    private let dimension: CGFloat = 36

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TransferValueView(transaction: transaction).opacity(opactiy)
            Image("ico-arrow-down").frame(width: dimension, height: dimension)
            AddressCell(address: transaction.to).frame(height: 50)
        }
    }

    var opactiy: Double {
        [.cancelled, .failed].contains(transaction.status) ? 0.5 : 1
    }
}

struct CustomTransactionDetailsHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        let transaction = CustomTransactionViewModel()
        transaction.to = "0x71592E6Cbe7779D480C1D029e70904041F8f602A"
        transaction.confirmationCount = 1
        transaction.threshold = 2
        transaction.formattedDate = "Apr 25, 2020 — 1:01:42PM"
        transaction.nonce = "2"
        transaction.amount = "5"
        transaction.tokenSymbol = " ETH"
        transaction.dataLength = 40
        transaction.status = .success

        return CustomTransactionDetailsHeaderView(transaction: transaction)
    }
}
