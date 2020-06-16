//
//  SettingChangeTransaction.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class SettingChangeTransaction: BaseTransactionViewModel {

    var title: String

    override init() {
        title = ""
        super.init()
    }

    override init(_ tx: Transaction, _ safe: SafeStatusRequest.Response)  {
        title = tx.dataDecoded!.method
        super.init(tx, safe)
    }

}
