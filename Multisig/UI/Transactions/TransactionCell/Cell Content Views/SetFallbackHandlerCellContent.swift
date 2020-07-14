//
//  SetFallbackHandlerCellContent.swift
//  Multisig
//
//  Created by Moaaz on 6/30/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SetFallbackHandlerCellContent: View {
    let address: Address
    var body: some View {
        HStack {
            Image("ico-settings-tx")
            AddressCell(address: address.checksummed,
                        title: App.shared.gnosisSafe.fallbackHandlerLabel(fallbackHandler: address),
                        style: .shortAddressNoShareGrayColor)

            Spacer()

            BodyText("Set fallback \n handler")
                .multilineTextAlignment(.trailing)
                .fixedSize()
        }
    }
}

struct SetFallbackHandlerTransactionCell_Previews: PreviewProvider {
    static var previews: some View {
        SetFallbackHandlerCellContent(address: "0xb35Ac2DF4f0D0231C5dF37C1f21e65569600bdd2")
    }
}
