//
//  TransactionCell.swift
//  Multisig
//
//  Created by Moaaz on 6/4/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionCell: View {

    let transaction: TransactionViewModel

    var body: some View {
        VStack (alignment: .leading, spacing: 4) {
            CellContent(transaction: transaction).opacity(opacity)
            StatusView(transaction: transaction, opacity: opacity)
        }
        .padding()
        .onAppear {
            App.shared.theme.resetRowsSelection()
        }
    }

    var opacity: Double {
        switch transaction.status {
        case .waitingExecution, .waitingConfirmation, .pending, .success:
             return 1
        case .failed, .cancelled:
            return 0.5
        }
    }
}

struct TransactionCell_Previews: PreviewProvider {
    static var previews: some View {
        let transaction = ChangeMasterCopyTransactionViewModel()
        transaction.contractAddress = "0x71592E6Cbe7779D480C1D029e70904041F8f602A"
        transaction.contractVersion = "1.1.1"
        transaction.confirmationCount = 1
        transaction.threshold = 2
        transaction.formattedDate = "Apr 25, 2020 — 1:01:42PM"
        transaction.nonce = "2"
        transaction.status = .failed

        //disabled mode
        return TransactionCell(transaction: transaction)
    }
}
