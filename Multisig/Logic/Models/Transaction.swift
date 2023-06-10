//
//  Transaction.swift
//  Multisig
//
//  Created by Moaaz on 6/1/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Version
import Ethereum
import JsonRpc2
import CryptoSwift
import Solidity
import SafeWeb3

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
        guard safe.addressValue == wcRequest.from.address, let chainId = safe.chain?.id else { return nil }

        self.safe = wcRequest.from
        self.chainId = chainId
        self.safeVersion = Version(safe.contractVersion!)

        self.to = wcRequest.to ?? AddressString.zero
        self.value = wcRequest.value ?? "0"
        self.data = wcRequest.data
        self.operation = .call
        self.safeTxGas = wcRequest.gas ?? "0"
        self.nonce = UInt256String(safe.nonce ?? 0)

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

    init?(transaction: EthereumTransaction, safe: Safe) {
        guard let chainId = safe.chain?.id else { return nil }

        self.safe = AddressString(transaction.from != nil ? Address(transaction.from!) : Address.zero)
        self.chainId = chainId
        self.safeVersion = Version(safe.contractVersion!)

        self.to = AddressString(transaction.to != nil ? Address(transaction.to!) : Address.zero)
        self.value = UInt256String(transaction.value?.quantity ?? 0)
        self.data = DataString(hex: transaction.data.hex())
        self.operation = .call
        self.safeTxGas = UInt256String(transaction.gas?.quantity ?? 0)
        self.nonce = UInt256String(safe.nonce ?? 0)

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

    init?(safe: Safe,
          toAddress: Address,
          tokenAddress: Address,
          amount: UInt256String?,
          safeTxGas: UInt256String?,
          nonce: UInt256String?) {

        if tokenAddress == Address.zero {
            self.init(safeAddress: safe.addressValue,
                      chainId: safe.chain!.id!,
                      toAddress: toAddress,
                      contractVersion: safe.contractVersion!,
                      amount: amount,
                      data: Data(),
                      safeTxGas: safeTxGas,
                      nonce: nonce ?? "0")
        } else {
            let input = ERC20.transfer(
                to: Sol.Address(stringLiteral: toAddress.checksummedWithoutPrefix),
                value: Sol.UInt256(amount?.value ?? 0)
            ).encode()

            self.init(safeAddress: safe.addressValue,
                      chainId: safe.chain!.id!,
                      toAddress: tokenAddress,
                      contractVersion: safe.contractVersion!,
                      amount: "0",
                      data: input,
                      safeTxGas: safeTxGas,
                      nonce: nonce ?? "0")
        }
    }

    init?(safeAddress: Address,
          chainId: String,
          toAddress: Address,
          contractVersion: String,
          amount: UInt256String?,
          data: Data,
          safeTxGas: UInt256String?,
          nonce: UInt256String,
          operation: SCGModels.Operation = .call,
          baseGas: UInt256String = "0",
          gasPrice: UInt256String = "0",
          gasToken: Address = Address.zero,
          refundReceiver: Address = Address.zero) {
        self.safe = AddressString(safeAddress)
        self.chainId = chainId
        self.safeVersion = Version(contractVersion)

        self.to = AddressString(toAddress)
        self.value = amount ?? "0"
        self.data = DataString(data)
        self.operation = operation
        self.safeTxGas = safeTxGas ?? "0"

        self.nonce = nonce

        // For contracts starting 1.3.0 we setup safeTxGas to zero
        if self.safeVersion! >= Version(1, 3, 0) {
            self.safeTxGas = UInt256String(0)
        }

        self.baseGas = baseGas
        self.gasPrice = gasPrice
        self.gasToken = AddressString(gasToken)
        self.refundReceiver = AddressString(refundReceiver)

        updateSafeTxHash()
    }

    mutating func update(nonce: UInt256String?, safeTxGas: UInt256String?) {
        if let nonce = nonce {
            self.nonce = nonce
        }
        if let safeTxGas = safeTxGas {
            self.safeTxGas = safeTxGas
        }

        safeTxHash = safeTransactionHash()
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

extension Transaction {
    public enum PaymentMethod {
        case signerAccount
        case relayer
    }
}
