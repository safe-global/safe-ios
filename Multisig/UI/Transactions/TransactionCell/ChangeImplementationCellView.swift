//
//  ChangeImplementationViewCell.swift
//  Multisig
//
//  Created by Moaaz on 6/4/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ChangeImplementationCellView: View {
    let transaction: ChangeImplementationTransactionViewModel
    var body: some View {
        HStack {
            Image("ico-settings-tx")
            AddressCell(address: transaction.contractAddress, title: transaction.contractVersion, style: .shortAddressNoShareGrayColor)

            Spacer()

            Text("Change \n mastercopy").body().multilineTextAlignment(.trailing).fixedSize()
        }
    }
}

struct ChangeImplementationCellView_Previews: PreviewProvider {
    static var previews: some View {
        let transaction = ChangeImplementationTransactionViewModel()
        transaction.contractAddress = "0x71592E6Cbe7779D480C1D029e70904041F8f602A"
        transaction.contractVersion = "1.1.1"
        transaction.confirmationCount = 1
        transaction.threshold = 2
        transaction.formattedDate = "Apr 25, 2020 — 1:01:42PM"
        transaction.nonce = "2"
        transaction.status = .success
        return ChangeImplementationCellView(transaction: transaction)
    }
}
