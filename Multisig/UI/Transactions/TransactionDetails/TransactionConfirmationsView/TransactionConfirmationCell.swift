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
                if [TransactionConfiramtionStatusViewStyle.canceled, TransactionConfiramtionStatusViewStyle.executed].contains(style) {
                    VerticalBarView().hidden()
                }
                else {
                    VerticalBarView()
                }

                AddressCell(address: address)
            }
        }
    }
}

struct TransactionConfirmationCell_Previews: PreviewProvider {
    static var previews: some View {
        TransactionConfirmationCell(address: "0x71592E6Cbe7779D480C1D029e70904041F8f602A", style: .executed)
    }
}
