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
    var to: AddressString?
    var value: UInt256String?
    var data: DataString?
    var operation: GnosisSafeOperation?
    var gasToken: AddressString?
    var safeTxGas: UInt256String?
    var baseGas: UInt256String?
    var gasPrice: UInt256String?
    var refundReceiver: AddressString?
    var nonce: UInt256String?
    var executionDate: Date?
    var submissionDate: Date?
    var modified: Date?
    var blockNumber: UInt256String?
    var transactionHash: DataString?
    var safeTxHash: DataString?
    var executor: AddressString?
    var isExecuted: Bool?
    var isSuccessful: Bool?
    var tokenAddress: AddressString?
    var ethGasPrice: UInt256String?
    var gasUsed: UInt256String?
    var fee: UInt256String?
    var origin: String?
    var dataDecoded: TransactionData?
    var confirmationsRequired: UInt256String?
    var confirmations: [TransactionConfirmation]?
    var signatures: DataString?
    var transfers: [TransactionTransfer]?
    var txType: TransactionType?

    static func browserURL(hash: String) -> URL {
        App.configuration.services.etehreumBlockBrowserURL
            .appendingPathComponent("tx").appendingPathComponent(hash)
    }
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
