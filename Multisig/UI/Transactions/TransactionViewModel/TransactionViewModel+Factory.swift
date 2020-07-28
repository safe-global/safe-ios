//
//  TransactionViewModel+Factory.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension TransactionViewModel {

    static func create(from tx: Transaction, _ info: SafeStatusRequest.Response) -> [TransactionViewModel] {
        // ask each class to create view models
        // and take the first recognized result
        [
            TransferTransactionViewModel.self,
            SettingChangeTransactionViewModel.self,
            ChangeImplementationTransactionViewModel.self,
            CustomTransactionViewModel.self
        ]
        .map { $0.viewModels(from: tx, info: info) }
        .first { !$0.isEmpty }
        ?? []
    }

}
