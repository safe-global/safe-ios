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

import SwiftCryptoTokenFormatter

struct MultiSendActionDetailsViewV2: View {
    var index: Int
    var multiSendTx: SCG.DataDecoded.Parameter.ValueDecoded.MultiSendTx
    private let eth = App.shared.tokenRegistry.token(address: .ether)!
    private let padding: CGFloat = 11
    var body: some View {
        VStack {
            Text(title).headline().padding()

            List {
                CustomTransactionDetailsHeaderViewV2(
                    amount: amount,
                    dataLength: UInt256(multiSendTx.data.data.count),
                    logoURL: eth.logo,
                    symbol: eth.symbol,
                    status: .success,
                    to: multiSendTx.to.address.checksummed)
                    .padding(.vertical, padding)

                HexDataCellView(data: dataWithLength)

                if let params = multiSendTx.dataDecoded?.parameters {
                    ForEach(0..<params.count) { index in
                        ParameterViewV2(parameter: params[index])
                    }
                }
            }
        }
        .onAppear {
            trackEvent(.transactionsDetailsAction)
        }
    }

    var amount: String {
        let decimalAmount = BigDecimal(-Int256(multiSendTx.value.value),
                                       Int(clamping: eth.decimals!))
        return TokenFormatter().string(
            from: decimalAmount,
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
            forcePlusSign: true
        )
    }

    var title: String {
        if let data = multiSendTx.dataDecoded {
            return data.method
        } else {
            return "Action #\(index + 1)"
        }
    }

    var dataWithLength: DataWithLength {
        (UInt256(multiSendTx.data.data.count), multiSendTx.data.data.toHexStringWithPrefix())
    }
}

struct CustomTransactionDetailsHeaderViewV2: View {
    var amount: String
    var dataLength: UInt256?
    var logoURL: URL?
    var symbol: String
    var status: SCG.TxStatus
    var to: String
    private let dimension: CGFloat = 36

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TransferValueViewV2(
                amount: amount,
                dataLength: dataLength,
                isOutgoing: true,
                logoURL: logoURL,
                symbol: symbol).opacity(opactiy)

            Image("ico-arrow-down").frame(width: dimension, height: dimension)

            AddressCell(address: to).frame(height: 50)
        }
    }

    var opactiy: Double {
        [.cancelled, .failed].contains(status) ? 0.5 : 1
    }
}

struct TransferValueViewV2: View {
    var amount: String
    var dataLength: UInt256?
    var isOutgoing: Bool
    var logoURL: URL?
    var symbol: String
    private let dimension: CGFloat = 36

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            tokenImage.frame(width: dimension, height: dimension)

            VStack (alignment: .leading) {
                Text("\(amount) \(symbol)").body(isOutgoing ? .gnoDarkBlue : .gnoHold)

                if let dataLength = dataLength {
                    Text("\(String(dataLength)) bytes").footnote()
                }
            }
        }
    }

    @ViewBuilder
    var tokenImage: some View {
        if symbol == App.shared.tokenRegistry.token(address: .ether)?.symbol {
            TokenImage.ether
        } else if logoURL != nil  {
            TokenImage(url: logoURL)
        } else {
            TokenImage.placeholder
        }
    }
}
