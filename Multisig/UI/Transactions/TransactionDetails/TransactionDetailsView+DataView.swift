//
//  TransactionDetailsView+DataView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension TransactionDetailsView {

    struct DataView: View {
        let transaction: TransactionViewModel

        @ViewBuilder var body: some View {
            if data != nil {
                VStack (alignment: .leading) {
                    BoldText("Data")
                    ExpandableButton(title: "\(data!.length) Bytes", value: data!.data)
                }.padding(.vertical, 11)
            } else {
                EmptyView()
            }
        }

        var data: (length: Int, data: String)? {
            guard let customTransaction = transaction as? CustomTransactionViewModel else {
                return nil
            }

            return (length: customTransaction.dataLength, data: customTransaction.data)
        }

    }
}
