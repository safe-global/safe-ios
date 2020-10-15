//
//  TransferTransactionSummeryViewModel.swift
//  Multisig
//
//  Created by Moaaz on 9/2/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftCryptoTokenFormatter

class TransferTransactionViewModel: TransactionViewModel, TransferAmmountViewModel {
    var address: String = ""
    var isOutgoing: Bool = true
    var amount: String = ""
    var tokenSymbol: String = ""
    var tokenLogoURL: String = ""

    override func bind(info: TransactionInfo) {
        let transferInfo = info as! TransferTransactionInfo

        isOutgoing = transferInfo.direction == .outgoing
        address = (isOutgoing ? transferInfo.recipient : transferInfo.sender).address.checksummed

        let sign: Int256 = isOutgoing ? -1 : +1

        var value: Int256
        var decimals: UInt256
        var symbol: String?
        var logoURL: String?

        if let etherTransferInfo = transferInfo.transferInfo as? EtherTransferInfo {
            value = Int256(etherTransferInfo.value.value)
            let eth = App.shared.tokenRegistry.token(address: .ether)!
            decimals = eth.decimals
            symbol = eth.symbol
            logoURL = eth.logo?.absoluteString
        } else if let erc721TransferInfo = transferInfo.transferInfo as? Erc721TransferInfo {
            symbol = erc721TransferInfo.tokenSymbol ?? "NFT"
            value = 1
            decimals = 0
            logoURL = erc721TransferInfo.logoUri
        } else {
            let erc20TransferInfo = transferInfo.transferInfo as! Erc20TransferInfo
            value = Int256(erc20TransferInfo.value.value)
            decimals = (try? UInt256(erc20TransferInfo.decimals ?? 0)) ?? 0
            symbol = erc20TransferInfo.tokenSymbol ?? "ERC20"
            logoURL = erc20TransferInfo.logoUri
        }

        let decimalAmount = BigDecimal(value * sign,
                                       Int(clamping: decimals))
        amount = TokenFormatter().string(
            from: decimalAmount,
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
            forcePlusSign: true
        )

        tokenSymbol = symbol ?? ""
        tokenLogoURL = logoURL ?? ""
    }

    class func isValid(info: TransactionInfo) -> Bool {
        info is TransferTransactionInfo
    }

    override class func viewModels(from tx: SCGTransaction) -> [TransactionViewModel] {
        isValid(info: tx.txInfo) ? [TransferTransactionViewModel(tx)] : []
    }
}
