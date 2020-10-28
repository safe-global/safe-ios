//
//  CustomTransactionSummaryViewModel.swift
//  Multisig
//
//  Created by Moaaz on 9/2/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftCryptoTokenFormatter

class CustomTransactionViewModel: TransactionViewModel, TransferAmmountViewModel {
    var dataLength: UInt256 = 0
    var to: String = ""
    var isOutgoing: Bool = false
    var amount: String = ""
    var tokenSymbol: String = ""
    var tokenLogoURL: String = ""

    override func bind(info: TransactionInfo) {
        let customTransactionInfo = info as! CustomTransactionInfo
        dataLength = customTransactionInfo.dataSize.value
        to = customTransactionInfo.to.address.checksummed

        let eth = App.shared.tokenRegistry.token(address: .ether)!
        tokenSymbol = eth.symbol
        tokenLogoURL = eth.logo?.absoluteString ?? ""

        isOutgoing = true

        let decimalAmount = BigDecimal(-Int256(customTransactionInfo.value.value),
                                       Int(clamping: eth.decimals))
        amount = TokenFormatter().string(
            from: decimalAmount,
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
            forcePlusSign: true
        )
    }

    class func isValid(info: TransactionInfo) -> Bool {
        info is CustomTransactionInfo
    }

    override class func viewModels(from tx: SCGTransaction) -> [TransactionViewModel] {
        isValid(info: tx.txInfo) ? [CustomTransactionViewModel(tx)] : []
    }
}
