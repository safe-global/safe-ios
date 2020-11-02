//
//  TokenBalance.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftCryptoTokenFormatter

struct TokenBalance: Identifiable, Hashable {
    var id: String {
        address
    }
    var imageURL: URL?
    let address: String
    let symbol: String
    let balance: String
    let balanceUsd: String
}

extension TokenBalance {
    init(_ response: SafeBalancesRequest.Response) {
        self.init(address: response.tokenAddress?.address ?? .ether,
                  symbol: response.token?.symbol,
                  logoUri: response.token?.logoUri,
                  tokenBalance: response.balance,
                  decimals: response.token?.decimals,
                  fiatBalance: response.balanceUsd)
    }

    init(_ item: SCGBalance) {
        self.init(address: item.tokenInfo.address.address,
                  symbol: item.tokenInfo.symbol,
                  logoUri: item.tokenInfo.logoUri,
                  tokenBalance: item.balance,
                  decimals: item.tokenInfo.decimals,
                  fiatBalance: item.fiatBalance)
    }

    init(address: Address, symbol: String?, logoUri: String?, tokenBalance: UInt256String, decimals: UInt256String?, fiatBalance: String) {
        self.address = address.checksummed
        self.symbol = symbol ?? "ETH"
        self.imageURL = logoUri.flatMap { URL(string: $0) }

        let tokenFormatter = TokenFormatter()
        let amount = Int256(tokenBalance.value)
        let precision = decimals?.value ?? 18 // ETH

        self.balance = tokenFormatter.string(
            from: BigDecimal(amount, Int(clamping: precision)),
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",")

        self.balanceUsd = Self.displayCurrency(from: fiatBalance)
    }

    static var serverCurrencyFormatter: NumberFormatter = {
        let currencyFormatter = NumberFormatter()
        // server always sends us number in en_US locale
        currencyFormatter.locale = Locale(identifier: "en_US")
        return currencyFormatter
    }()

    static var displayCurrencyFormatter: NumberFormatter = {
        let currencyFormatter = NumberFormatter()
        // Product decision: we display currency in user locale
        currencyFormatter.locale = Locale.autoupdatingCurrent
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "USD"
        return currencyFormatter
    }()

    static func displayCurrency(from serverValue: String) -> String {
        let number = serverCurrencyFormatter.number(from: serverValue) ?? 0
        // resulting nil value should never happen
        return displayCurrencyFormatter.string(from: number)!
    }
}
