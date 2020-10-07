//
//  CoinBalancesModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class CoinBalancesModel: NetworkContentViewModel {
    var balances = [TokenBalance]()

    func reload() {
        super.reload { safe -> [TokenBalance] in
            guard let addressString = safe.address else {
                throw "Error: safe does not have address. Please reload."
            }
            let address = try Address(from: addressString)
            let balancesResponse = try App.shared.safeTransactionService.safeBalances(at: address)
            let tokenBalances = balancesResponse.map { TokenBalance($0) }
            return tokenBalances
        } receive: { [weak self] tokenBalances in
            guard let `self` = self else { return }
            self.balances = tokenBalances
        }
    }
}
