//
//  EnableDisableModuleTransactionCellView.swift
//  Multisig
//
//  Created by Moaaz on 6/30/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct EnableDisableModuleTransactionCellView: View {
    let transaction: ChangeMasterCopyTransactionViewModel
    var body: some View {
        HStack {
            Image("ico-settings-tx")
            AddressCell(address: transaction.contractAddress, title: transaction.contractVersion, style: .shortAddressNoShareGrayColor)

            Spacer()

            BodyText("Change \n mastercopy").multilineTextAlignment(.trailing).fixedSize()
        }
    }
}

struct EnableDisableModuleTransactionCellView_Previews: PreviewProvider {
    static var previews: some View {
        EnableDisableModuleTransactionCellView()
    }
}
