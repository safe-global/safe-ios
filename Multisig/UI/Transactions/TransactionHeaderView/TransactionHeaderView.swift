//
//  TransactionHeaderView.swift
//  Multisig
//
//  Created by Moaaz on 6/10/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionHeaderView: View {
    let transaction: TransactionViewModel
    var body: some View {
        contentView.padding(.top)
    }

    var contentView: some View {
        let transferTransaction = transaction as? TransferTransactionViewModel
        let settingChangeTransaction = transaction as? SettingChangeTransactionViewModel
        let changeMasterCopyTransaction = transaction as? ChangeMasterCopyTransactionViewModel
        let customTransaction = transaction as? CustomTransactionViewModel

        return ZStack {
            if customTransaction != nil {
                TransferTransactionDetailsHeaderView(transaction: customTransaction!)
            } else if transferTransaction != nil {
                TransferTransactionDetailsHeaderView(transaction: transferTransaction!)
            } else if settingChangeTransaction != nil {
                SettingsChangeTransactionDetailsHeaderView(transaction: settingChangeTransaction!)
            } else if changeMasterCopyTransaction != nil {
                ChangeMastercopyTransactionDetailsHeaderView(transaction: changeMasterCopyTransaction!)
            } else {
                EmptyView()
            }
        }
    }
}

struct TransactionHeaderView_Previews: PreviewProvider {
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

        return TransactionHeaderView(transaction: transaction)
    }
}
