//
//  TransferTransactionHeaderView.swift
//  Multisig
//
//  Created by Moaaz on 6/16/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransferTransactionDetailsHeaderView: View {
    let transaction: TransferTransactionViewModel

    private let dimention: CGFloat = 36

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            fromView
            Image("ico-arrow-down").frame(width: dimention, height: dimention)
            toView
        }
    }

    var fromView: some View {
        ZStack {
            if transaction.isOutgoing  {
                valueView
            } else {
                AddressCell(address: transaction.address).frame(height: 50)
            }
        }
    }

    var toView: some View {
        ZStack {
            if transaction.isOutgoing  {
                AddressCell(address: transaction.address).frame(height: 50)
            } else {
                valueView
            }
        }
    }

    var valueView: some View {
        TransferValueView(transaction: transaction)
    }
}

struct TransferTransactionHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        let transaction = CustomTransactionViewModel()
        transaction.address = "0x71592E6Cbe7779D480C1D029e70904041F8f602A"
        transaction.confirmationCount = 1
        transaction.threshold = 2
        transaction.formattedDate = "Apr 25, 2020 — 1:01:42PM"
        transaction.nonce = "2"
        transaction.amount = "5"
        transaction.tokenSymbol = " ETH"
        transaction.isOutgoing = true
        transaction.dataLength = 40
        transaction.status = .success

        return TransferTransactionDetailsHeaderView(transaction: transaction)
    }
}
