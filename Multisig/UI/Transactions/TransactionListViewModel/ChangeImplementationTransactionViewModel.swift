//
//  ChangeImplementationTransactionSummaryViewModel.swift
//  Multisig
//
//  Created by Moaaz on 9/2/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChangeImplementationTransactionViewModel: TransactionViewModel {
    var contractVersion: String = ""
    var contractAddress: String = ""
    
    override func bind(info: TransactionInfo) {
        let settingsChangeTransactionInfo = info as! SettingsChangeTransactionInfo
        let changeImplementation = settingsChangeTransactionInfo.settingsInfo as! ChangeImplementationSettingsChangeTransactionSammaryInfo
        let implementation = changeImplementation.implementation.address
        contractAddress = implementation.checksummed
        contractVersion = GnosisSafe().versionNumber(implementation: implementation) ?? "Unknown"
    }

    class func isValid(info: TransactionInfo) -> Bool {
        guard let settingsChangeTransactionInfo = info as? SettingsChangeTransactionInfo,
            settingsChangeTransactionInfo.settingsInfo is ChangeImplementationSettingsChangeTransactionSammaryInfo else {
            return false
        }

        return true
    }

    override class func viewModels(from tx: TransactionSummary) -> [TransactionViewModel] {
        guard isValid(info: tx.txInfo) else {
            return []
        }

        return [ChangeImplementationTransactionViewModel(tx)]
    }

    override class func viewModels(from tx: TransactionDetails) -> [TransactionViewModel] {
        guard isValid(info: tx.txInfo) else {
            return []
        }
        
        return [ChangeImplementationTransactionViewModel(tx)]
    }
}
