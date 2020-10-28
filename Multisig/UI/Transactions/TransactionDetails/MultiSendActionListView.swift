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

            if let dataDecoded = transaction.dataDecoded {
                Text(dataDecoded.method).body()
            } else {
                Text("Action #\(index + 1)")
            }
        }
    }
}

struct MultiSendActionDetailsView: View {
    var index: Int
    var transaction: MultiSendTransaction

    var body: some View {
        List {
            CustomTransactionDetailsHeaderView(transaction: CustomTransactionViewModel(transaction))

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

import SwiftCryptoTokenFormatter

extension CustomTransactionViewModel {
    convenience init(_ tx: MultiSendTransaction) {
        self.init()
        dataLength = UInt256(tx.data.data.count)
        to = tx.to.address.checksummed
        let eth = App.shared.tokenRegistry.token(address: .ether)!
        tokenSymbol = eth.symbol
        tokenLogoURL = eth.logo?.absoluteString ?? ""
        let decimalAmount = BigDecimal(Int256(tx.value.value),
                                       Int(clamping: eth.decimals))
        amount = TokenFormatter().string(
            from: decimalAmount,
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
            forcePlusSign: true
        )
    }
}
