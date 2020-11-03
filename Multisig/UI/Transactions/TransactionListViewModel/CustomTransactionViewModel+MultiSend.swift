//
//  CustomTransactionViewModel+MultiSend.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 28.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftCryptoTokenFormatter

extension CustomTransactionViewModel {
    convenience init(_ tx: MultiSendTransaction) {
        self.init()
        dataLength = UInt256(tx.data.data.count)
        to = tx.to.address.checksummed

        let eth = App.shared.tokenRegistry.token(address: .ether)!
        tokenSymbol = eth.symbol
        tokenLogoURL = eth.logo?.absoluteString ?? ""

        isOutgoing = true

        let decimalAmount = BigDecimal(-Int256(tx.value.value),
                                       Int(clamping: eth.decimals!))
        amount = TokenFormatter().string(
            from: decimalAmount,
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
            forcePlusSign: true
        )
    }
}
