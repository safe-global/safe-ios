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
    var contractVersion: String?
    var factoryUsed: String?

    init(_ tx: CreationTransaction, _ safe: SafeStatusRequest.Response)  {
        super.init()
        title = "Safe created"
        creator = tx.creator?.address.checksummed
        implementationUsed = tx.masterCopy?.address.checksummed
        if let implementationUsed = implementationUsed {
            contractVersion = GnosisSafe().versionNumber(implementation: Address(exactly: implementationUsed)) ?? "Unknown"
        }
        factoryUsed = tx.factoryAddress?.address.checksummed
        hash = tx.transactionHash?.description
        date = tx.created
        formattedCreatedDate = date.map { Self.dateFormatter.string(from: $0) } ?? ""
    }
}

