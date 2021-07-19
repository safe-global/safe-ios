//
//  SafeContract.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class SafeContract: Contract {
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @param safeTxGas Gas that should be used for the Safe transaction.
    /// @param baseGas Gas costs for that are indipendent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Gas price that should be used for the payment calculation.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
    private let execTransactionsMethodSignature =
        "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)"

    func nonce() throws -> UInt256 {
        try decodeUInt(invoke("nonce()"))
    }

    func execTransaction(_ tx: Transaction,
                         confirmations: [SCGModels.Confirmation],
                         confirmationsRequired: UInt64) -> Data {
        let txData = tx.data?.data ?? Data()
        let txDataOffset = 320 // tx.data offset is always 32*10
        let txDataEncoded = encodeBytes(txData)

        let signaturesOffset = txDataOffset + txDataEncoded.count
        let signaturesData = signatures(confirmations: confirmations, confirmationsRequired: confirmationsRequired)
        let signaturesEncoded = encodeBytes(signaturesData)

        return invocation(execTransactionsMethodSignature,
                   encodeAddress(tx.to.address),
                   encodeUInt(tx.value.value),
                   encodeUInt(txDataOffset),
                   encodeUInt(tx.operation.uint256),
                   encodeUInt(tx.safeTxGas.value),
                   encodeUInt(tx.baseGas.value),
                   encodeUInt(tx.gasPrice.value),
                   encodeAddress(tx.gasToken.address),
                   encodeAddress(tx.refundReceiver.address),
                   encodeUInt(signaturesOffset),
                   txDataEncoded,
                   signaturesEncoded)
    }

    //  https://docs.gnosis.io/safe/docs/contracts_signatures/
    func signatures(confirmations: [SCGModels.Confirmation], confirmationsRequired: UInt64) -> Data {
        // The most gas efficient are ECDSA signatures
        // Second most gas efficient are Pre-Validated Signatures
        // The least gas efficient are Contract Signatures (EIP-1271)

        // currently all confirmations are ECDSA signatures at this stage
        let sortedRequiredConfirmationsHex = confirmations
            .sorted(by: { $0.signer.value.description < $1.signer.value.description })[0..<Int(confirmationsRequired)]
            .map { $0.signature.data.toHexString() }
            .joined()

        return Data(hex: sortedRequiredConfirmationsHex)
    }
}
