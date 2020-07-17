//
//  SettingChangeTransactionViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class SettingChangeTransactionViewModel: TransactionViewModel {

    var title: String
    var method: SmartContractMethodCall?
    override init() {
        title = ""
        super.init()
    }

    override init(_ tx: Transaction, _ safe: SafeStatusRequest.Response)  {
        title = tx.dataDecoded!.method
        method = MethodRegistry.GnosisSafeSettings.method(from: tx.dataDecoded!)
        super.init(tx, safe)
    }

    override class func viewModels(from tx: Transaction, info: SafeStatusRequest.Response) -> [TransactionViewModel] {
        guard MethodRegistry.GnosisSafeSettings.isValid(tx) else {
            return []
        }
        return [SettingChangeTransactionViewModel(tx, info)]
    }
}
