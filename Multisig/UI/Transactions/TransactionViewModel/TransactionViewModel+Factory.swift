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
        [
            TransferTransactionViewModel.self,
            SettingChangeTransactionViewModel.self,
            ChangeMasterCopyTransactionViewModel.self,
            CustomTransactionViewModel.self
        ]
        .map { $0.viewModels(from: tx, info: info) }
        .first { !$0.isEmpty }
        ?? []
    }

}
