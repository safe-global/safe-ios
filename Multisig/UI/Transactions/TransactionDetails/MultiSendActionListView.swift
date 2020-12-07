//
//  MultiSendActionListView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 28.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct MultiSendActionListView: View {
    var multiSend: MultiSendCall

    var body: some View {
        List {
            ForEach(0..<multiSend.transactions.count) { index in
                NavigationLink(destination: MultiSendActionDetailsView(index: index, transaction: multiSend.transactions[index])) {
                    MultiSendActionListRow(index: index, transaction: multiSend.transactions[index])
                }
            }
        }
        .onAppear {
            trackEvent(.transactionDetailsActionList)
        }
        .navigationBarTitle("Multisend")
    }
}

struct MultiSendActionListRow: View {
    var index: Int
    var transaction: MultiSendTransaction
    var body: some View {
        HStack(alignment: .center) {
            AddressCell(address: transaction.to.address.checksummed, style: .shortAddressNoShare)
                .layoutPriority(1)

            Spacer()

            if let dataDecoded = transaction.dataDecoded {
                Text(dataDecoded.method).body()
            } else {
                Text("Action #\(index + 1)")
            }
        }
    }
}

struct MultiSendActionListViewV2: View {
    var transactions: [SCG.DataDecoded.Parameter.ValueDecoded.MultiSendTx]

    var body: some View {
        List {
            ForEach(0..<transactions.count) { index in
                NavigationLink(destination: MultiSendActionDetailsViewV2(index: index, multiSendTx: transactions[index])) {
                    MultiSendActionListRowV2(index: index, transaction: transactions[index])
                }
            }
        }
        .onAppear {
            trackEvent(.transactionDetailsActionList)
        }
        .navigationBarTitle("Multisend")
    }
}


struct MultiSendActionListRowV2: View {
    var index: Int
    var transaction: SCG.DataDecoded.Parameter.ValueDecoded.MultiSendTx
    var body: some View {
        HStack(alignment: .center) {
            AddressCell(address: transaction.to.address.checksummed, style: .shortAddressNoShare)
                .layoutPriority(1)

            Spacer()

            if let dataDecoded = transaction.dataDecoded {
                Text(dataDecoded.method).body()
            } else {
                Text("Action #\(index + 1)")
            }
        }
    }
}
