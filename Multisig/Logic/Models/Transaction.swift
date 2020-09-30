//
//  Transaction.swift
//  Multisig
//
//  Created by Moaaz on 6/1/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

// Transaction domain model based on https://docs.gnosis.io/safe/docs/contracts_tx_execution/#transaction-hash
// and '/safes/{address}/transactions/' endpoint required data of transaction service
struct Transaction {
    // required by a smart contract
    let to: AddressString?
    let value: UInt256String
    let data: DataString?
    let operation: Operation
    let safeTxGas: UInt256String
    let baseGas: UInt256String
    let gasPrice: UInt256String
    let gasToken: AddressString?
    let refundReceiver: AddressString // zero address if no refund receiver is set
    let nonce: UInt256String
    // computed based on other properties
    let safeTxHash: HashString // can be computed from the
}

#warning("TODO: make a validatione of safeTxHash here")
extension Transaction {
    init(txData: TransactionDetailsData, multiSigTxInfo: MultisigExecutionDetails) {
        to = txData.to
        value = txData.value
        data = txData.hexData
        operation = txData.operation
        safeTxGas = multiSigTxInfo.safeTxGas
        baseGas = multiSigTxInfo.baseGas
        gasPrice = multiSigTxInfo.gasPrice
        gasToken = multiSigTxInfo.gasToken
        refundReceiver = multiSigTxInfo.refundReceiver
        nonce = multiSigTxInfo.nonce
        safeTxHash = multiSigTxInfo.safeTxHash
    }
}
