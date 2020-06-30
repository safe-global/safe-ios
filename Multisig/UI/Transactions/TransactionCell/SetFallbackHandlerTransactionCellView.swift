//
//  SetFallbackHandlerTransactionCellView.swift
//  Multisig
//
//  Created by Moaaz on 6/30/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SetFallbackHandlerTransactionCellView: View {
    let transaction: ChangeMasterCopyTransactionViewModel
    var body: some View {
        HStack {
            Image("ico-settings-tx")
            AddressCell(address: address.checksummed, title: App.shared.gnosisSafe.fallbackHandlerLabel(fallbackHandler: address), style: .shortAddressNoShareGrayColor)

            Spacer()

            BodyText("Set fallback \n handler").multilineTextAlignment(.trailing).fixedSize()
        }
    }
}

struct SetFallbackHandlerTransactionCellView_Previews: PreviewProvider {
    static var previews: some View {
        SetFallbackHandlerTransactionCellView()
    }
}
