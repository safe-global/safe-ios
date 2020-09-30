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
    let gasToken: UInt256String?
    let refundReceiver: AddressString?
    let nonce: UInt256String

    // required by a transaction service
    let safeTxHash: HashString
    let sender: AddressString
    let signature: SignatureString
}
