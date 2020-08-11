//
//  CreationTransactionViewModel.swift
//  Multisig
//
//  Created by Moaaz on 8/10/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class CreationTransactionViewModel: SettingChangeTransactionViewModel {
    var creator: String?
    var implementationUsed: String?
    var factoryUsed: String?

    init(_ tx: CreationTransaction, _ safe: SafeStatusRequest.Response)  {
        super.init()
        title = "Safe created"
        creator = tx.creator?.address.checksummed
        implementationUsed = tx.masterCopy?.address.checksummed
        factoryUsed = tx.factoryAddress?.address.checksummed
        hash = tx.transactionHash?.description
        date = tx.created
        formattedDate = date.map { Self.dateFormatter.string(from: $0) } ?? ""
    }
}

