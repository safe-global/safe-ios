//
//  TransactionConfirmationCell.swift
//  Multisig
//
//  Created by Moaaz on 6/10/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionConfirmationCell: View {
    let address: String
    let style: TransactionConfiramtionStatusViewStyle

    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            TransactionConfiramtionStatusView(style: style)

            HStack {
                VerticalBarView().opacity(hasVerticalBar ? 0 : 1)

                AddressCell(address: address)
            }
        }
    }

    var hasVerticalBar: Bool {
        [.canceled, .executed].contains(style)
    }
}

struct TransactionConfirmationCell_Previews: PreviewProvider {
    static var previews: some View {
        TransactionConfirmationCell(address: "0x71592E6Cbe7779D480C1D029e70904041F8f602A", style: .executed)
    }
}
