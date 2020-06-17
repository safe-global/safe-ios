//
//  ConfirmationsView.swift
//  Multisig
//
//  Created by Moaaz on 6/10/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionConfirmationsView: View {
    let transaction: TransactionViewModel
    let safe: Safe

    #warning("TODO: update after clarified requirements")

    var body: some View {
        assert(transaction.hasConfirmations)
        return VStack(alignment: .leading, spacing: 1) {
            TransactionConfirmationCell(address: transaction.confirmations!.first!.address, style: .created)

            ForEach(transaction.confirmations ?? [], id: \.address) { confirmation in
                TransactionConfirmationCell(address: confirmation.address, style: .confirmed)
            }

            if transaction.status == .success {
                TransactionConfirmationCell(address: transaction.confirmations!.last!.address, style: .executed)
            }
            else {
                actionsView
            }
        }
    }

    var actionsView: some View {
        VStack (alignment: .leading, spacing: 1) {
            if style != nil {
                TransactionConfiramtionStatusView(style: style!)
            }

            if transaction.status == .waitingConfirmation {
                if !isConfirmedBySelectedSafe {
                    VerticalBarView()
                }

                TransactionConfiramtionStatusView(style: .waitingConfirmations(transaction.remainingConfirmationsRequired))
            }
        }.fixedSize()
    }

    var style: TransactionConfiramtionStatusViewStyle? {
        let status = transaction.status
        if transaction.status == .canceled {
            return .canceled
        } else if transaction.status == .failed {
            return .failed
        } else if status == .waitingConfirmation {
            return isConfirmedBySelectedSafe ? nil : .confirm
        } else if status == .waitingExecution {
            return .execute
        }

        return nil
    }

    var isConfirmedBySelectedSafe: Bool {
        transaction.confirmations!.first { (confirmation) -> Bool in
            confirmation.address == safe.address
        } != nil
    }
}
