//
//  Transaction.swift
//  Multisig
//
//  Created by Moaaz on 6/1/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

// Transaction domain model based on https://docs.gnosis.io/safe/docs/contracts_tx_execution/#transaction-hash
struct Transaction: Codable {
    var safe: AddressString?
    var safeVersion: String?
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

    init?(wcRequest: WCSendTransactionRequest, safe: Safe, contractNonce: UInt256String) {
        dispatchPrecondition(condition: .notOnQueue(.main))

        guard safe.addressValue == wcRequest.from.address,
              let chainId = safe.network?.chainId,
              let network = safe.network else { return nil }

        self.safe = wcRequest.from
        self.chainId = chainId
        self.safeVersion = safe.contractVersion
        self.nonce = contractNonce

        if let latestTxNonce = try? App.shared.clientGatewayService
            .latestQueuedTransactionNonce(safeAddress: self.safe!.address, networkId: network.chainId!),
           latestTxNonce.value >= nonce.value {
            nonce = UInt256String(latestTxNonce.value + 1)
        }

        to = wcRequest.to ?? AddressString.zero
        value = wcRequest.value ?? "0"
        data = wcRequest.data
        operation = .call
        safeTxGas = wcRequest.gas ?? "0"
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
                                     safeVersion: String,
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
