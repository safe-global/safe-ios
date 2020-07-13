//
//  SetFallbackHandlerTransactionDetailsHeaderView.swift
//  Multisig
//
//  Created by Moaaz on 6/17/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SetFallbackHandlerTransactionDetailsHeaderView: View {
    let address: Address

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            BoldText("Set fallback handler:")
            AddressCell(address: address.checksummed, title: App.shared.gnosisSafe.fallbackHandlerLabel(fallbackHandler: address), style: .shortAddress)
        }
    }
}

struct SetFallbackHandlerTransactionDetailsHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SetFallbackHandlerTransactionDetailsHeaderView(address: "0xb35Ac2DF4f0D0231C5dF37C1f21e65569600bdd2")
    }
}
