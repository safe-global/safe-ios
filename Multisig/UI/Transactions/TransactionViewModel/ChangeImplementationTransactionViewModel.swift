//
//  ChangeImplementationTransactionViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class ChangeImplementationTransactionViewModel: TransactionViewModel {

    var contractVersion: String
    var contractAddress: String

    override init() {
        contractVersion = ""
        contractAddress = ""
        super.init()
    }

    override init(_ tx: Transaction, _ safe: SafeStatusRequest.Response)  {
        if let data = tx.dataDecoded,
            let call = MethodRegistry.GnosisSafeImplementation.ChangeImplementation(data: data) {
            contractAddress = call.implementation.checksummed
            contractVersion = GnosisSafe().versionNumber(implementation: call.implementation) ?? "Unknown"
        } else {
            contractAddress = Address.zero.checksummed
            contractVersion = "Unknown"
        }
        super.init(tx, safe)
    }

    override class func viewModels(from tx: Transaction, info: SafeStatusRequest.Response) -> [TransactionViewModel] {
        guard MethodRegistry.GnosisSafeImplementation.isValid(tx) else {
            return []
        }
        return [ChangeImplementationTransactionViewModel(tx, info)]
    }

}
