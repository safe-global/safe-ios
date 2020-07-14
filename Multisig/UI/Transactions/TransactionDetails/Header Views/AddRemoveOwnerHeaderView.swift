//
//  AddRemoveOwnerTransactionHeaderView.swift
//  Multisig
//
//  Created by Moaaz on 6/17/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddRemoveOwnerHeaderView: View {
    let state: State
    var address: Address
    var threshold: UInt256?

    var body: some View {
        VStack (alignment: .leading, spacing: 11) {
            BoldText(title)
            AddressCell(address: address.checksummed)

            if threshold != nil {
                KeyValueRow("Change required confirmations:", value: "\(threshold!)", enableCopy: false, color: Color.gnoDarkGrey)
            }
        }
    }

    var title: String {
        switch state {
        case .add:
            return "Add owner:"
        case .remove:
            return "Remove owner:"
        }
    }

    enum State {
        case add
        case remove
    }
}

struct AddRemoveOwnerTransactionHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        AddRemoveOwnerHeaderView(state: .add, address: "0xb35Ac2DF4f0D0231C5dF37C1f21e65569600bdd2", threshold: 1)
    }
}
