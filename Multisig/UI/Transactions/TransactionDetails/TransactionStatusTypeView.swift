//
//  TransactionStatusTypeView.swift
//  Multisig
//
//  Created by Moaaz on 6/15/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionStatusTypeView: View {
    let transaction: BaseTransactionViewModel
    var body: some View {
        VStack {
            HStack {
                Image(imageName)
                BodyText(title)

                if !displayStatusOnSecondLine {
                    TransactionStatusView(status: transaction.status)
                }
            }

            if displayStatusOnSecondLine {
                TransactionStatusView(status: transaction.status)
            }
        }
    }

    var title: String {
        if let _ = transaction as? CustomTransaction {
            return "Custom transaction"
        } else if let transfer = transaction as? TransferTransaction {
            return transfer.isOutgoing ? "Outgoing transfer" : "Incoming transfer"
        }

        return "Modify settings"
    }

    var imageName: String {
        if let _ = transaction as? CustomTransaction {
            return "ico-custom-tx"
        } else if let transfer = transaction as? TransferTransaction {
            return transfer.isOutgoing ? "ico-outgoing-tx" : "ico-incoming-tx"
        }

        return "ico-settings-tx"
    }

    var displayStatusOnSecondLine: Bool {
        if [.waitingConfirmation, .waitingExecution].contains(transaction.status) {
            return true
        }

        return false
    }
}

struct TransactionStatusTypeView_Previews: PreviewProvider {
    static var previews: some View {
        let transaction = ChangeMasterCopyTransaction()
        transaction.contractAddress = "0x71592E6Cbe7779D480C1D029e70904041F8f602A"
        transaction.contractVersion = "1.1.1"
        transaction.confirmationCount = 1
        transaction.threshold = 2
        transaction.formattedDate = "Apr 25, 2020 — 1:01:42PM"
        transaction.nonce = "2"
        transaction.status = .failed

        return TransactionStatusTypeView(transaction: transaction)
    }
}
