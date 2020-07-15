//
//  SetFallbackHandlerSummaryView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SetFallbackHandlerSummaryView: View {
    let label: String
    let address: Address
    let image = "ico-settings-tx"
    let description = "Set fallback \n handler"

    var body: some View {
        HStack {
            Image(image)
            AddressCell(address: address.checksummed,
                        title: label,
                        style: .shortAddressNoShareGrayColor)
            Spacer()
            BodyText(description)
                .multilineTextAlignment(.trailing)
                .fixedSize()
        }
    }
}

extension SetFallbackHandlerSummaryView {
    init(address: Address) {
        self.address = address
        self.label = App.shared.gnosisSafe
            .fallbackHandlerLabel(fallbackHandler: address)
    }
}

struct SetFallbackHandlerSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SetFallbackHandlerSummaryView(address: "0xb35Ac2DF4f0D0231C5dF37C1f21e65569600bdd2")
    }
}
