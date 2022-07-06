//
//  TokenBalance.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftCryptoTokenFormatter
import UIKit
import Solidity
import Ethereum

struct TokenBalance: Identifiable, Hashable {
    var id: String {
        address
    }
    var imageURL: URL?
    var image: UIImage?
    let address: String
    let name: String
    let symbol: String
    let balance: String
    let fiatBalance: String
    let balanceValue: BigDecimal
    let decimals: Int
}

extension TokenBalance {
    init(_ item: SCGBalance, code: String) {
        self.init(address: item.tokenInfo.address.address,
                  name: item.tokenInfo.name,
                  symbol: item.tokenInfo.symbol,
                  logoUri: item.tokenInfo.logoUri,
                  tokenBalance: item.balance,
                  decimals: item.tokenInfo.decimals,
                  fiatBalance: item.fiatBalance,
                  code: code)
    }

    init(address: Address,
         name: String?,
         symbol: String?,
         logoUri: String?,
         tokenBalance: UInt256String,
         decimals: UInt256String?,
         fiatBalance: String,
         code: String) {
        self.address = address.checksummed
        let coin = Chain.nativeCoin

        self.name = name ?? coin?.name ?? "Ether"
        self.symbol = symbol ?? coin?.symbol ?? "ETH"
        self.imageURL = logoUri.flatMap { URL(string: $0) } ?? coin?.logoUrl

        let tokenFormatter = TokenFormatter()
        let amount = Int256(tokenBalance.value)
        let precision = decimals?.value ?? (coin?.decimals).map(UInt256.init(clamping:)) ?? 18

        self.decimals = Int(clamping: precision)
        self.balanceValue = BigDecimal(amount, self.decimals)
        self.balance = tokenFormatter.string(
            from: balanceValue,
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",")

        self.fiatBalance = Self.displayCurrency(from: fiatBalance, code: code)
    }

    static var serverCurrencyFormatter: NumberFormatter = {
        let currencyFormatter = NumberFormatter()
        // server always sends us number in en_US locale
        currencyFormatter.locale = Locale(identifier: "en_US")
        return currencyFormatter
    }()

    static func displayCurrency(from serverValue: String, code: String) -> String {
        let number = serverCurrencyFormatter.number(from: serverValue) ?? 0
        let formatter = TokenFormatter()
        let amount = Int256(number.doubleValue * 100)
        let precision = 2
        let currencyCode = code
        let value = formatter.string(from: BigDecimal(amount, precision),
                        decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
                        thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",")
        return "\(value) \(currencyCode)"
    }

    var balanceWithSymbol: String {
        "\(balance) \(symbol)"
    }

    var fullBalanceWithSymbol: String {
        let value = Sol.UInt256(big: balanceValue.value.magnitude)
        let tokenAmount = Eth.TokenAmount(
                value: value,
                decimals: decimals)
        let fullBalance = tokenAmount.description
        return "\(fullBalance) \(symbol)"
    }

    static let nativeTokenAddress: String = Address.zero.checksummed
}
