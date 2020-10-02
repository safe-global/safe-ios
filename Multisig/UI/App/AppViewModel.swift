//
//  AppViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class AppViewModel {
    static var shared = AppViewModel()

    var coins = CoinBalancesModel()
    var collectibles = CollectibleBalancesModel()
    var transactions = LoadingTransactionListViewModel()
    var safeSettings = LoadingSafeSettingsViewModel()

    var txDetails = LoadingTransactionDetailsViewModel()


    var txDetailsPool = [String: LoadingTransactionDetailsViewModel]()

    func details(_ tx: TransactionViewModel) -> LoadingTransactionDetailsViewModel {
        precondition(!tx.id.isEmpty)

        if txDetailsPool[tx.id] == nil {
            let model = LoadingTransactionDetailsViewModel()
            txDetailsPool[tx.id] = model
        }

        return txDetailsPool[tx.id]!
    }

}
