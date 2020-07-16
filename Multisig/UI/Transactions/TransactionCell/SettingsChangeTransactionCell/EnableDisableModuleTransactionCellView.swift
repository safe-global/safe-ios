//
//  EnableDisableModuleTransactionCellView.swift
//  Multisig
//
//  Created by Moaaz on 6/30/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct EnableDisableModuleTransactionCellView: View {
    let state: State
    var address: Address
    
    var body: some View {
        HStack {
            Image("ico-settings-tx")
            AddressCell(address: address.checksummed, style: .shortAddressNoShare)
            Spacer()
            Text(title).body().multilineTextAlignment(.trailing).fixedSize()
        }
    }

    var title: String {
        switch state {
        case .enable:
            return "Enable \n module"
        case .disable:
            return "Disable \n module"
        }
    }

    enum State {
        case enable
        case disable
    }
}

struct EnableDisableModuleTransactionCellView_Previews: PreviewProvider {
    static var previews: some View {
        EnableDisableModuleTransactionCellView(state: .enable, address: "0xb35Ac2DF4f0D0231C5dF37C1f21e65569600bdd2")
    }
}
