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
    var imageURL: URL? {
        // will be replaced when https://github.com/gnosis/safe-transaction-service/issues/86 is ready
        return URL(string: "https://gnosis-safe-token-logos.s3.amazonaws.com/\(String(describing: address)).png")!
    }
    let address: String
    let symbol: String
    let balance: String
    let balanceUsd: String

    init(_ response: SafeBalancesRequest.Response) {
        let tokenAddress = response.tokenAddress?.address ?? AddressRegistry.ether
        self.address = tokenAddress.checksummed
        self.symbol = response.token?.symbol ?? "ETH"

        let tokenFormatter = TokenFormatter()

        let amount = Int256(response.balance.value)

        let precision =  response.token?.decimals.value ?? 18 // ETH

        self.balance = tokenFormatter.string(
            from: BigDecimal(amount, Int(clamping: precision)),
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",")

        let currencyFormatter = NumberFormatter()
        // server always sends us number in en_US locale
        currencyFormatter.locale = Locale(identifier: "en_US")
        let number = currencyFormatter.number(from: response.balanceUsd) ?? 0
        // Product decision: we display currency in user locale
        currencyFormatter.locale = Locale.autoupdatingCurrent
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "USD"
        self.balanceUsd = currencyFormatter.string(from: number)!
    }
}
