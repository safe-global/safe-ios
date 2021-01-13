//
//  Transaction.swift
//  Multisig
//
//  Created by Moaaz on 6/1/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

// Transaction domain model based on https://docs.gnosis.io/safe/docs/contracts_tx_execution/#transaction-hash
struct Transaction {
    // required by a smart contract
    let to: AddressString
    let value: UInt256String
    let data: DataString
    let operation: SCG.Operation
    let safeTxGas: UInt256String
    let baseGas: UInt256String
    let gasPrice: UInt256String
    let gasToken: AddressString
    // zero address if no refund receiver is set
    let refundReceiver: AddressString
    let nonce: UInt256String
    // computed based on other properties
    let safeTxHash: HashString?
}

extension Transaction {
    init?(tx: SCG.TransactionDetails) {
        guard let txData = tx.txData,
              case let SCG.TransactionDetails.DetailedExecutionInfo.multisig(multiSigTxInfo)? = tx.detailedExecutionInfo else {
            return nil
        }
        to = txData.to
        value = txData.value
        data = txData.hexData ?? DataString(Data())
        operation = SCG.Operation(rawValue: txData.operation.rawValue)!
        safeTxGas = multiSigTxInfo.safeTxGas
        baseGas = multiSigTxInfo.baseGas
        gasPrice = multiSigTxInfo.gasPrice
        gasToken = multiSigTxInfo.gasToken
        refundReceiver = multiSigTxInfo.refundReceiver
        nonce = multiSigTxInfo.nonce
        safeTxHash = multiSigTxInfo.safeTxHash
    }

    var safeEncodedTxData: Data {
        [
            Safe.DefaultEIP712SafeAppTxTypeHash,
            to.data32,
            value.data32,
            EthHasher.hash(data.data),
            operation.data32,
            safeTxGas.data32,
            baseGas.data32,
            gasPrice.data32,
            gasToken.data32,
            refundReceiver.data32,
            nonce.data32
        ]
        .reduce(Data()) { $0 + $1 }
    }

    func encodeTransactionData(for safe: AddressString) -> Data {
        let ERC191MagicByte = Data([0x19])
        let ERC191Version1Byte = Data([0x01])
        return [
            ERC191MagicByte,
            ERC191Version1Byte,
            EthHasher.hash(Safe.domainData(for: safe)),
            EthHasher.hash(safeEncodedTxData)
        ].reduce(Data()) { $0 + $1 }
    }
}
