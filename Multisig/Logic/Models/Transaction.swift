//
//  Transaction.swift
//  Multisig
//
//  Created by Moaaz on 6/1/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Version

// Transaction domain model based on https://docs.gnosis.io/safe/docs/contracts_tx_execution/#transaction-hash
struct Transaction: Codable {
    var safe: AddressString?
    var safeVersion: Version?
    var chainId: String?

    // required by a smart contract
    let to: AddressString
    let value: UInt256String
    let data: DataString?
    let operation: SCGModels.Operation
    // can be modified for WalletConnect transactions
    var safeTxGas: UInt256String
    let baseGas: UInt256String
    let gasPrice: UInt256String
    let gasToken: AddressString
    // zero address if no refund receiver is set
    let refundReceiver: AddressString
    // can be modified for WalletConnect transactions
    var nonce: UInt256String
    // computed based on other properties
    var safeTxHash: HashString!
    var transactionHash: HashString?
}

extension Transaction {
    init?(tx: SCGModels.TransactionDetails) {
        guard let txData = tx.txData,
              case let SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(multiSigTxInfo)? = tx.detailedExecutionInfo else {
            return nil
        }
        to = txData.to.value
        value = txData.value
        data = txData.hexData ?? DataString(Data())
        operation = SCGModels.Operation(rawValue: txData.operation.rawValue)!
        safeTxGas = multiSigTxInfo.safeTxGas
        baseGas = multiSigTxInfo.baseGas
        gasPrice = multiSigTxInfo.gasPrice
        gasToken = multiSigTxInfo.gasToken
        refundReceiver = multiSigTxInfo.refundReceiver.value
        nonce = multiSigTxInfo.nonce
        safeTxHash = multiSigTxInfo.safeTxHash
    }

    init?(wcRequest: WCSendTransactionRequest, safe: Safe) {
        dispatchPrecondition(condition: .notOnQueue(.main))

        guard safe.addressValue == wcRequest.from.address, let chainId = safe.chain?.id else { return nil }

        self.safe = wcRequest.from
        self.chainId = chainId
        self.safeVersion = Version(safe.contractVersion!)

        self.to = wcRequest.to ?? AddressString.zero
        self.value = wcRequest.value ?? "0"
        self.data = wcRequest.data
        self.operation = .call
        self.safeTxGas = wcRequest.gas ?? "0"

        let estimationResult: SCGModels.TransactionEstimation
        do {
            estimationResult = try App.shared.clientGatewayService
                .syncTransactionEstimation(
                    chainId: chainId,
                    safeAddress: safe.addressValue,
                    to: to.address,
                    value: value.value,
                    data: data?.data,
                    operation: operation)

            self.nonce = UInt256String(estimationResult.latestNonce.value + 1)

            if let estimatedSafeTxGas = UInt256(estimationResult.safeTxGas) {
                self.safeTxGas = UInt256String(estimatedSafeTxGas)
            }
        } catch {
            LogService.shared.error("Estimation error: \(error)")
            return nil
        }

        // For contracts starting 1.3.0 we setup safeTxGas to zero
        if self.safeVersion! >= Version(1, 3, 0) {
            self.safeTxGas = UInt256String(0)
        }

        baseGas = "0"
        gasPrice = "0"
        gasToken = AddressString.zero
        refundReceiver = AddressString.zero

        updateSafeTxHash()
    }

    mutating func updateSafeTxHash() {
        safeTxHash = safeTransactionHash()
    }

    func encodeTransactionData() -> Data {
        let ERC191MagicByte = Data([0x19])
        let ERC191Version1Byte = Data([0x01])
        return [
            ERC191MagicByte,
            ERC191Version1Byte,
            EthHasher.hash(Safe.domainData(for: safe!, version: safeVersion!, chainId: chainId!)),
            EthHasher.hash(safeEncodedTxData)
        ].reduce(Data()) { $0 + $1 }
    }

    static func rejectionTransaction(safeAddress: Address,
                                     nonce: UInt256String,
                                     safeVersion: Version,
                                     chainId: String) -> Transaction {

        var transaction = Transaction(to: AddressString(safeAddress),
                                      value: "0",
                                      data: "0x",
                                      operation: SCGModels.Operation.call,
                                      safeTxGas: "0",
                                      baseGas: "0",
                                      gasPrice: "0",
                                      gasToken: "0x0000000000000000000000000000000000000000",
                                      refundReceiver: "0x0000000000000000000000000000000000000000",
                                      nonce: nonce,
                                      safeTxHash: nil)
        transaction.safe = AddressString(safeAddress)
        transaction.safeVersion = safeVersion
        transaction.chainId = chainId

        transaction.safeTxHash = transaction.safeTransactionHash()

        return transaction
    }

    var safeEncodedTxData: Data {
        [
            Safe.DefaultEIP712SafeAppTxTypeHash,
            to.data32,
            value.data32,
            EthHasher.hash(data!.data),
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

    private func safeTransactionHash() -> HashString? {
        let data = encodeTransactionData()
        return try? HashString(hex: EthHasher.hash(data).toHexString())
    }
}
