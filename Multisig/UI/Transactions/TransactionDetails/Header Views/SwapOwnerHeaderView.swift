//
//  SwapOwnerTransactionHeaderView.swift
//  Multisig
//
//  Created by Moaaz on 6/17/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SwapOwnerHeaderView: View {
    let removedAddress: Address
    let addedAddress: Address

    var body: some View {
        VStack(alignment: .leading) {
            AddRemoveOwnerHeaderView(state: .remove, address: removedAddress)
            AddRemoveOwnerHeaderView(state: .add, address: addedAddress)
        }
    }
}

struct SwapOwnerTransactionHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SwapOwnerHeaderView(removedAddress: "0xb35Ac2DF4f0D0231C5dF37C1f21e65569600bdd2", addedAddress: "0xb35Ac2DF4f0D0231C5dF37C1f21e65569600bdd2")
    }
}
