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
    private var txDetailsPool = [String: StateMachineTransactionDetailsViewModel]()

    func details(_ tx: TransactionViewModel) -> StateMachineTransactionDetailsViewModel {
        precondition(!tx.id.isEmpty)

        if txDetailsPool[tx.id] == nil {
            let model = StateMachineTransactionDetailsViewModel()
            txDetailsPool[tx.id] = model
        }

        return txDetailsPool[tx.id]!
    }

}
