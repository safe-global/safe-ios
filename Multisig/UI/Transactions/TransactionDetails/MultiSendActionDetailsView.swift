//
//  MultiSendActionDetailsView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 28.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct MultiSendActionDetailsView: View {
    var index: Int
    var transaction: MultiSendTransaction
    let padding: CGFloat = 11
    var body: some View {
        List {
            CustomTransactionDetailsHeaderView(transaction: CustomTransactionViewModel(transaction))
                .padding(.vertical, padding)
            HexDataCellView(data: dataWithLength)

            if let params = transaction.dataDecoded?.parameters {
                ForEach(params) { param in
                    ParameterView(parameter: param)
                }
            }
        }
        .navigationBarTitle(title)
        .onAppear {
            trackEvent(.transactionsDetailsAction)
        }
    }

    var title: String {
        if let data = transaction.dataDecoded {
            return data.method
        } else {
            return "Action #\(index + 1)"
        }
    }

    var dataWithLength: DataWithLength {
        (UInt256(transaction.data.data.count), transaction.data.data.toHexStringWithPrefix())
    }
}
