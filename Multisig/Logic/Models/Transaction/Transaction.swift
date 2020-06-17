//
//  Transaction.swift
//  Multisig
//
//  Created by Moaaz on 6/1/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

// Information about structure described in https://github.com/gnosis/safe/issues/324
struct Transaction: Decodable, Hashable {

    var safe: AddressString?
    let to: AddressString?
    let value: UInt256String?
    let data: DataString?
    let operation: GnosisSafeOperation?
    let gasToken: AddressString?
    let safeTxGas: UInt256String?
    let baseGas: UInt256String?
    let gasPrice: UInt256String?
    let refundReceiver: AddressString?
    let nonce: UInt256String?
    let executionDate: Date?
    let submissionDate: Date?
    let modified: Date?
    let blockNumber: UInt256String?
    let transactionHash: DataString?
    let safeTxHash: DataString?
    let executor: AddressString?
    let isExecuted: Bool?
    let isSuccessful: Bool?
    let tokenAddress: AddressString?
    let ethGasPrice: UInt256String?
    let gasUsed: UInt256String?
    let fee: UInt256String?
//    let origin: AddressString?  // "{\"url\":\"https://gnosis-apps.netlify.com/compound\",\"name\":\"Compound\"}"
    let dataDecoded: TransactionData?
    let confirmationsRequired: UInt256String?
    let confirmations: [TransactionConfirmation]?
    let signatures: DataString?
    let transfers: [TransactionTransfer]?
    let txType: TransactionType?
}

enum TransactionType: String, Decodable {
    case multiSig = "MULTISIG_TRANSACTION"
    case ethereum = "ETHEREUM_TRANSACTION"
    case module = "MODULE_TRANSACTION"
}

enum GnosisSafeOperation: Int, Decodable {
    case call = 0
    case delegateCall = 1
}
