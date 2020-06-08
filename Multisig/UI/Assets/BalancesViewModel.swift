//
//  AssetsViewModel.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine
import SwiftCryptoTokenFormatter
import BigInt

struct TokenBalance: Identifiable, Hashable {
    var id: Int {
        hashValue
    }
    var imageURL: URL? {
        // will be replaced when https://github.com/gnosis/safe-transaction-service/issues/86 is ready
        guard let address = address else { return nil }
        return URL(string: "https://gnosis-safe-token-logos.s3.amazonaws.com/\(String(describing: address)).png")!
    }
    let address: String?
    let symbol: String
    let balance: String
    let balanceUsd: String

    init(_ response: SafeBalancesRequest.Response) {
        self.address = response.tokenAddress
        self.symbol = response.token?.symbol ?? "ETH"

        let tokenFormatter = TokenFormatter()
        self.balance = tokenFormatter.safeString(from: response.balance, decimals: response.token?.decimals)

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

extension TokenFormatter {

    func safeString(from: String?, decimals: Int? = nil, isNegative: Bool = false, forcePlusSign: Bool = false) -> String {
        string(
            from: BigDecimal((isNegative ? -1 : 1) * (BigInt(from ?? "0") ?? 0), decimals ?? 18),
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
            forcePlusSign: forcePlusSign
        )
    }
}

class BalancesViewModel: ObservableObject {
    @Published var balances = [TokenBalance]()
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil

    private var subscribers = Set<AnyCancellable>()

    init(safe: Safe) {
        isLoading = true
        Just(safe.address!)
            .setFailureType(to: Error.self)
            .flatMap { address in
                Future<[TokenBalance], Error> { promise in
                    DispatchQueue.global().async {
                        do {
                            let balancesResponse = try App.shared.safeTransactionService.safeBalances(at: address)
                            let tokenBalances = balancesResponse.map { TokenBalance($0) }
                            promise(.success(tokenBalances))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }, receiveValue:{ tokenBalances in
                self.balances = tokenBalances
            })
            .store(in: &subscribers)
    }
}
