//
//  SettingsTransactionCellView.swift
//  Multisig
//
//  Created by Moaaz on 6/4/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SettingsChangeTransactionCellView: View {
    let transaction: SettingChangeTransactionViewModel
    var body: some View {
        HStack {
            Image("ico-settings-tx")
            BodyText(transaction.title)
            Spacer()
        }
    }
}

struct SettingsChangeTransactionCellView_Previews: PreviewProvider {
    static var previews: some View {
        let transaction = SettingChangeTransactionViewModel()
        transaction.title = "Add owner"
        transaction.confirmationCount = 1
        transaction.formattedDate = "Apr 25, 2020 — 1:01:42PM"
        transaction.nonce = "2"
        transaction.status = .success
        transaction.threshold = 2
        return SettingsChangeTransactionCellView(transaction: transaction)
    }
}
