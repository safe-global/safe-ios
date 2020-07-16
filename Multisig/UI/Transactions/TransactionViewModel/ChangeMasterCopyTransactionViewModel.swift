//
//  ChangeMasterCopyTransactionViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class ChangeMasterCopyTransactionViewModel: TransactionViewModel {

    var contractVersion: String
    var contractAddress: String

    override init() {
        contractVersion = ""
        contractAddress = ""
        super.init()
    }

    override init(_ tx: Transaction, _ safe: SafeStatusRequest.Response)  {
        if let data = tx.dataDecoded,
            let call = MethodRegistry.GnosisSafeMasterCopy.ChangeMasterCopy(data: data) {
            contractAddress = call.masterCopy.checksummed
            contractVersion = GnosisSafe().versionNumber(masterCopy: call.masterCopy) ?? "Unknown"
        } else {
            contractAddress = Address.zero.checksummed
            contractVersion = "Unknown"
        }
        super.init(tx, safe)
    }

    override class func viewModels(from tx: Transaction, info: SafeStatusRequest.Response) -> [TransactionViewModel] {
        guard MethodRegistry.GnosisSafeMasterCopy.isValid(tx) else {
            return []
        }
        return [ChangeMasterCopyTransactionViewModel(tx, info)]
    }

}
