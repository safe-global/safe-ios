//
//  ReviewExecutionCellBuilder.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class ReviewExecutionCellBuilder: TransactionDetailCellBuilder {

    override func buildTransaction(_ tx: SCGModels.TransactionDetails) {
        // nothing to do for creation transaction
        if case let SCGModels.TxInfo.creation(_) = tx.txInfo {
            return
        }
        buildHeader(tx)
        buildAssetContract(tx)
        buildExecutionOptions(tx)
    }

    func buildExecutionOptions(_ tx: SCGModels.TransactionDetails) {
        buildExecutedWithAccount(tx)
        buildEstimatedGasFee(tx)
        buildAdvancedParameters(tx)
    }

    func buildExecutedWithAccount(_ tx: SCGModels.TransactionDetails) {
        // new type of cell
        // we need the key info
        // we need account balance
    }

    func buildEstimatedGasFee(_ tx: SCGModels.TransactionDetails) {
        // we need total gas fee
        // we need the fiat value of gas fee
    }

    func buildAdvancedParameters(_ tx: SCGModels.TransactionDetails) {
        // cell that leads to the 'advanced params' screen for this transaction.
    }
}
