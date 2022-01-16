//
//  TransactionExecutionController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Solidity
import Version
import SafeAbi
import Ethereum
import Web3
import JsonRpc2
import CryptoSwift
import WalletConnectSwift

struct UserDefinedTransactionParameters: Equatable {
    var nonce: Sol.UInt64?
    var gas: Sol.UInt64?

    var gasPrice: Sol.UInt256?

    var maxFeePerGas: Sol.UInt256?
    var maxPriorityFee: Sol.UInt256?
}

class TransactionExecutionController {
    private var safe: Safe
    private var chain: Chain
    private var transaction: SCGModels.TransactionDetails

    let estimationController: TransactionEstimationController

    var ethTransaction: EthTransaction?

    // 1.5 gwei in wei (1.5 x 10^9)
    let defaultMinerTip: Sol.UInt256 = 1_500_000_000

    var userParameters = UserDefinedTransactionParameters() {
        didSet {
            updateEthTransactionWithUserValues()
        }
    }

    var chainId: String {
        chain.id!
    }

    init(safe: Safe, chain: Chain, transaction: SCGModels.TransactionDetails) {
        self.safe = safe
        self.chain = chain
        self.transaction = transaction
        self.estimationController = TransactionEstimationController(rpcUri: chain.authenticatedRpcUrl.absoluteString)
    }

    // returns the execution keys valid for executing this transaction
    func executionKeys() -> [KeyInfo] {
        // all keys that can sign this tx on its chain.
            // currently, only wallet connect keys are chain-specific, so we filter those out.
        guard let allKeys = try? KeyInfo.all(), !allKeys.isEmpty else {
            return []
        }

        let validKeys = allKeys.filter { keyInfo in
            // if it's a wallet connect key which chain doesn't match then do not use it
            if keyInfo.keyType == .walletConnect,
               let data = keyInfo.metadata,
               let connection = KeyInfo.WalletConnectKeyMetadata.from(data: data),
               // when chainId is 0 then it is 'any' chain
               connection.walletInfo.chainId != 0 &&
                String(describing: connection.walletInfo.chainId) != chain.id {
                return false
            }
            // else use the key
            return true
        }

        return validKeys
    }

    var selectedKey: (key: KeyInfo, balance: AccountBalanceUIModel)? {
        didSet {
            if oldValue?.key != selectedKey?.key {
                // the old user parameters for nonce will be incorrect anymore
                userParameters.nonce = nil
            }
        }
    }

    var requiredBalance: Sol.UInt256? {
        ethTransaction?.requiredBalance
    }

    let keySelectionPolicy = OwnerKeySelectionPolicy()

    // cancellable process to find a default execution key
    func findDefaultKey(completion: @escaping () -> Void) -> URLSessionTask? {
        // use safe's owner addresses
        let ownerAddresses = safe.ownersInfo?.map { $0.address } ?? []

        // make database query to get all keys
        let keys = executionKeys()

        // make network request to fetch balances
        let balanceLoader = DefaultAccountBalanceLoader(chain: chain)
        balanceLoader.requiredBalance = requiredBalance ?? 0

        let task = balanceLoader.loadBalances(for: keys) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                // if request cancelled, do nothing, don't call completion.
                if (error as NSError).code == URLError.cancelled.rawValue &&
                    (error as NSError).domain == NSURLErrorDomain {
                    return
                }
                // if request fails with some error treat as if balances are set to 0
                let balances: [AccountBalanceUIModel] = .init(
                    repeating: AccountBalanceUIModel(displayAmount: "", isEnabled: true), count: keys.count)
                self.findDefaultKey(keys: keys, balances: balances, ownerAddresses: ownerAddresses)
                completion()

            case .success(let balances):
                self.findDefaultKey(keys: keys, balances: balances, ownerAddresses: ownerAddresses)

                completion()
            }
        }
        return task
    }

    private func findDefaultKey(
        keys: [KeyInfo],
        balances: [AccountBalanceUIModel],
        ownerAddresses: [Address]
    ) {
        assert(keys.count == balances.count)
        let candidates = zip(keys, balances).map { key, balance in
            OwnerKeySelectionPolicy.KeyCandidate(
                key: key,
                balance: balance.amount ?? 0,
                isOwner: ownerAddresses.contains(key.address))
        }

        let bestCandidate = self.keySelectionPolicy.defaultExecutionKey(
            in: candidates,
            requiredAmount: self.requiredBalance ?? 0
        )
        if let bestCandidate = bestCandidate {
            let result = zip(keys, balances).first { $0.0 == bestCandidate.key }!
            self.selectedKey = result
        } else {
            self.selectedKey = nil
        }
    }

    func estimate(completion: @escaping (Error?) -> Void) -> URLSessionTask? {
        var tx: EthTransaction
        do {
            let keyAddress = selectedKey?.key.address
            let solAddress = try keyAddress.map { try Sol.Address($0.data32) }
            let minerTip = userParameters.maxPriorityFee ?? defaultMinerTip

            tx = try ethTransaction(from: solAddress, minerTip: minerTip)
        } catch {
            completion(error)
            return nil
        }

        let task = estimationController.estimate(transaction: tx) { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let estimatedTx):
                // at this point the estimatedTx contains parameters estimated by API
                self.ethTransaction = estimatedTx
                self.updateEthTransactionWithUserValues()
                completion(nil)
            }
        }

        return task
    }

    // returns unestimated transaction based on the safe contract version and chain.
    //
    // transaction must be a multisig transaction with the txData and detailed execution info set.
    // all the values must be valid solidity types (addresses, integers, etc.)
    //
    // safe must have the version and address set
    // chain must have l2 and chainId set
    func ethTransaction(from: Sol.Address?, minerTip: Sol.UInt256) throws -> EthTransaction {
        guard
            let txData = transaction.txData,
            let executionInfo = transaction.detailedExecutionInfo,
            case let SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(multisigDetails) = executionInfo
        else {
            throw TransactionExecutionError(code: -1, message: "Execution of non-multisig transactions is not supported")
        }

        guard let safeVersionString = safe.version,
              let chainIdString = chain.id,
              let chainId = Sol.UInt256(chainIdString),
              let chainFeatures = chain.features
        else {
            throw TransactionExecutionError(code: -2, message: "Missing required parameters of safe and chain information.")
        }
        let chainIsL2 = chain.l2
        let safeAddress = safe.addressValue

        // build the 'input' data

        let input: Data

        // select the appropriate Gnosis Safe contract ABI version
        let safeVersion = Version(safeVersionString) ?? Version(1, 3, 0)
        let isL2Contract = chainIsL2 && safeVersion >= Version(1, 3, 0)


        let ExecTransactionAbiFunctionType: GnosisSafeExecTransaction.Type

        if isL2Contract {
            // l2 1.3.0 abi
            ExecTransactionAbiFunctionType = GnosisSafeL2_v1_3_0.execTransaction.self
        } else {
            // ? ..< 1.1.1
            if safeVersion < Version(1, 1, 1) {
                ExecTransactionAbiFunctionType = GnosisSafe_v1_0_0.execTransaction.self
            }
            // 1.1.1 ..< 1.2.0
            else if safeVersion < Version(1, 2, 0) {
                ExecTransactionAbiFunctionType = GnosisSafe_v1_1_1.execTransaction.self
            }
            // 1.2.0 ..< 1.3.0
            else if safeVersion < Version(1, 3, 0) {
                ExecTransactionAbiFunctionType = GnosisSafe_v1_2_0.execTransaction.self
            }
            // >= 1.3.0
            else { // safeVersion >= Version(1, 3, 0)
                ExecTransactionAbiFunctionType = GnosisSafe_v1_3_0.execTransaction.self
            }
        }

        // build the EVM call data

        // All the signatures are sorted by the signer hex address and concatenated
        let signatures = multisigDetails.confirmations.sorted { lhs, rhs in
            lhs.signer.value.address.hexadecimal < rhs.signer.value.address.hexadecimal
        }.map { confirmation in
            confirmation.signature.data
        }.joined()

        // build safe transaction
        input = try ExecTransactionAbiFunctionType.init(
            to:  Sol.Address(txData.to.value.data32),
            value: Sol.UInt256(txData.value.data32),
            data: Sol.Bytes(storage: txData.hexData?.data ?? Data()),
            operation: Sol.UInt8(txData.operation.rawValue),
            safeTxGas: Sol.UInt256(multisigDetails.safeTxGas.data32),
            baseGas: Sol.UInt256(multisigDetails.baseGas.data32),
            gasPrice: Sol.UInt256(multisigDetails.gasPrice.data32),
            gasToken: Sol.Address(multisigDetails.gasToken.data32),
            refundReceiver: Sol.Address(multisigDetails.refundReceiver.value.data32),
            signatures: Sol.Bytes(storage: Data(signatures))
        ).encode()

        // build ethereum transaction, unestimated.
        let result: EthTransaction

        let isEIP1559 = chainFeatures.contains("EIP1559")
        if isEIP1559 {
            result = try Eth.TransactionEip1559(
                chainId: chainId,
                from: from,
                to: Sol.Address(safeAddress.data32),
                input: Sol.Bytes(storage: input),
                fee: .init(maxPriorityFee: minerTip)
            )
        } else {
            result = try Eth.TransactionLegacy(
                chainId: chainId,
                from: from,
                to: Sol.Address(safeAddress.data32),
                input: Sol.Bytes(storage: input)
            )
        }

        return result
    }

    func updateEthTransactionWithUserValues() {
        // take the values only if they were set by user (not nil)
        switch ethTransaction {
        case var ethTx as Eth.TransactionLegacy:
            ethTx.fee.gas = userParameters.gas ?? ethTx.fee.gas
            ethTx.fee.gasPrice = userParameters.gasPrice ?? ethTx.fee.gasPrice
            ethTx.nonce = userParameters.nonce ?? ethTx.nonce

            self.ethTransaction = ethTx

        case var ethTx as Eth.TransactionEip1559:
            ethTx.fee.gas = userParameters.gas ?? ethTx.fee.gas
            ethTx.fee.maxFeePerGas = userParameters.maxFeePerGas ?? ethTx.fee.maxFeePerGas
            ethTx.fee.maxPriorityFee = userParameters.maxPriorityFee ?? ethTx.fee.maxPriorityFee
            ethTx.nonce = userParameters.nonce ?? ethTx.nonce

            self.ethTransaction = ethTx

        default:
            break
        }
    }

    var isValid: Bool = false
    var errorMessage: String?

    func validate() {
        isValid = false

        guard let key = selectedKey, let keyBalance = key.balance.amount else {
            return
        }

        guard let requiredBalance = requiredBalance else {
            return
        }

        guard keyBalance >= requiredBalance else {
            errorMessage = "Insufficient balance for network fees"
            return
        }

        isValid = true
    }

    func update(signature: String) throws {
        // r{32}s{32}v{1} bytes
        guard let data = Data(exactlyHex: signature), data.count == 65 else {
            throw TransactionExecutionError(code: -6, message: "Signature format invalid")
        }
        let r = data[0..<32]
        let s = data[32..<64]
        var v = data[64]

        // safe signature for eth_sign
        if v == 31 || v == 32 {
            v -= 31
        } else if v == 27 || v == 28 {
            // eip-155 w/o chain id
            v -= 27
        } else if v >= 35 {
            // eip-155 with chain id
            v -= 35 + (UInt8(chainId) ?? 0) * 2
        }

        assert(v == 0 || v == 1, "v  must be 0, got: \(v)")

        try update(signature: (UInt(v), Array(r), Array(s)))
    }

    var intChainId: Int {
        guard let ethTransaction = ethTransaction else {
            return 0
        }

        switch ethTransaction {
        case let tx as Eth.TransactionLegacy:
            return tx.chainId.map { Int(truncatingIfNeeded: $0) } ?? 0

        case let tx as Eth.TransactionEip2930:
            return Int(truncatingIfNeeded: tx.chainId)

        case let tx as Eth.TransactionEip1559:
            return Int(truncatingIfNeeded: tx.chainId)

        default:
            return 0
        }
    }

    var isLegacyTx: Bool {
        guard let ethTransaction = ethTransaction else {
            return false
        }

        let result = ethTransaction is Eth.TransactionLegacy
        return result
    }

    func preimageForSigning() -> Data {
        guard let tx = self.ethTransaction else {
            preconditionFailure("transaction must exist")
        }
        return tx.preImageForSigning()
    }

    func hashForSigning() -> Data {
        guard let tx = self.ethTransaction else {
            preconditionFailure("transaction must exist")
        }
        return tx.hashForSigning().storage.storage
    }

    func update(signature: (v: UInt, r: [UInt8], s: [UInt8])) throws {
        guard var tx = self.ethTransaction else { return }

        let preimage = preimageForSigning()
        let publicKey = try EthereumPublicKey(
            message: preimage.bytes,
            v: EthereumQuantity(quantity: BigUInt(signature.v)),
            r: EthereumQuantity(signature.r),
            s: EthereumQuantity(signature.s))

        guard publicKey.address.hex(eip55: false) == tx.from!.description else {
            throw TransactionExecutionError(code: -3, message: "Signature does not match the signer address")
        }

        try tx.updateSignature(
            v: Sol.UInt256(signature.v),
            r: Sol.UInt256(Data(signature.r)),
            s: Sol.UInt256(Data(signature.s))
        )

        ethTransaction = tx
    }

    func walletConnectTransaction() -> Client.Transaction? {
        guard let ethTransaction = ethTransaction else {
            return nil
        }
        let clientTx: Client.Transaction

        switch ethTransaction {
        case let tx as Eth.TransactionLegacy:
            let rpcTx = EthRpc1.TransactionLegacy(tx)
            clientTx = .init(
                from: rpcTx.from!.hex,
                to: rpcTx.to?.hex,
                data: rpcTx.input.hex,
                gas: rpcTx.gas?.hex,
                gasPrice: rpcTx.gasPrice?.hex,
                value: rpcTx.value.hex,
                nonce: rpcTx.nonce?.hex,
                type: rpcTx.type.hex,
                accessList: nil,
                chainId: rpcTx.chainId?.hex,
                maxPriorityFeePerGas: nil,
                maxFeePerGas: nil
            )

        case let tx as Eth.TransactionEip2930:
            let rpcTx = EthRpc1.Transaction2930(tx)
            clientTx = .init(
                from: rpcTx.from!.hex,
                to: rpcTx.to?.hex,
                data: rpcTx.input.hex,
                gas: rpcTx.gas?.hex,
                gasPrice: rpcTx.gasPrice?.hex,
                value: rpcTx.value.hex,
                nonce: rpcTx.nonce?.hex,
                type: rpcTx.type.hex,
                accessList: nil, // access list initializer is not accessible
                chainId: rpcTx.chainId.hex,
                maxPriorityFeePerGas: nil,
                maxFeePerGas: nil
            )

        case let tx as Eth.TransactionEip1559:
            let rpcTx = EthRpc1.Transaction1559(tx)
            clientTx = .init(
                from: rpcTx.from!.hex,
                to: rpcTx.to?.hex,
                data: rpcTx.input.hex,
                gas: rpcTx.gas?.hex,
                gasPrice: nil,
                value: rpcTx.value.hex,
                nonce: rpcTx.nonce?.hex,
                type: rpcTx.type.hex,
                accessList: nil, // wallet connect lib doesn't provide initializer
                chainId: rpcTx.chainId.hex,
                maxPriorityFeePerGas: rpcTx.maxPriorityFeePerGas?.hex,
                maxFeePerGas: rpcTx.maxFeePerGas?.hex
            )
        default:
            return nil
        }

        return clientTx
    }

    func send(completion: @escaping (Result<Void, Error>) -> Void) -> URLSessionTask? {
        guard var tx = self.ethTransaction else { return nil }

        let rawTransaction = tx.rawTransaction()

        let sendRawTxMethod = EthRpc1.eth_sendRawTransaction(transaction: rawTransaction)

        let request: JsonRpc2.Request

        do {
            request = try sendRawTxMethod.request(id: .int(1))
        } catch {
            dispatchOnMainThread(completion(.failure(error)))
            return nil
        }

        let client = estimationController.rpcClient

        let task = client.send(request: request) { [weak self] response in
            guard let self = self else { return }

            guard let response = response else {
                let error = TransactionExecutionError(code: -4, message: "No response from server")
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            if let error = response.error {
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            guard let result = response.result else {
                let error = TransactionExecutionError(code: -5, message: "No result from server")
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            let txHash: EthRpc1.Data
            do {
                txHash = try sendRawTxMethod.result(from: result)
            } catch {
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            tx.hash = Eth.Hash(txHash.storage)
            self.ethTransaction = tx

            dispatchOnMainThread(completion(.success(())))
        }
        return task
    }
}

struct TransactionExecutionError: LocalizedError {
    let code: Int
    let message: String

    var errorDescription: String? {
        "\(message) (Error \(code))"
    }
}
