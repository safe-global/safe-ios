//
//  PendingTransactionMontior.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import JsonRpc2
import Ethereum
import Solidity

class PendingTransactionMonitor {
    static var globalTimer: Timer?
    static let shared = PendingTransactionMonitor()

    static func scheduleMonitoring(repeatInterval: TimeInterval = 10, runImmediately: Bool = true) {
        globalTimer?.invalidate()

        globalTimer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true, block: { _ in
            Self.shared.queryTransactionStatuses()
        })

        if runImmediately {
            Self.shared.queryTransactionStatuses()
        }
    }

    static func stopMonitoring() {
        globalTimer?.invalidate()
        shared.monitors = []
    }

    private var monitors: [ChainPendingTransactionMonitor] = []

    func queryTransactionStatuses() {
        // get chains
        let chains = Chain.all

        // create monitors
        monitors = chains.map(ChainPendingTransactionMonitor.init(chain:))

        // run each monitor
        for monitor in monitors {
            monitor.queryTransactionStatuses()
        }
    }
}

class ChainPendingTransactionMonitor {

    private let chain: Chain
    private let client: JsonRpc2.Client
    private var queryTask: URLSessionTask?

    init(chain: Chain) {
        let urlString = chain.authenticatedRpcUrl.absoluteString
        self.chain = chain
        client = JsonRpc2.Client(transport: JsonRpc2.ClientHTTPTransport(url: urlString), serializer: JsonRpc2.DefaultSerializer())
    }

    deinit {
        queryTask?.cancel()
    }

    func queryTransactionStatuses() {
        assert(chain.id != nil)
        let chainId = chain.id!

    // fetch pending transactions from the database
        let context = App.shared.coreDataStack.viewContext
        let statusPending = SCGModels.TxStatus.pending.rawValue

        let fetchRequest = CDEthTransaction.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "ethTxHash != nil AND chainId == %@ AND status == %@ AND taskId == nil", chainId, statusPending)

        let cdEthTransactions: [CDEthTransaction]

        do {
            cdEthTransactions = try context.fetch(fetchRequest)
        } catch {
            LogService.shared.debug("Transaction monitor [chain=\(chainId)]: failed to fetch transactions: \(error)")
            return
        }

        guard !cdEthTransactions.isEmpty else {
            // nothing to do
            return
        }

    // get receipts of those transactions
        // convert the transactions into receipt requests
        let rpcMethods = cdEthTransactions.compactMap { cdTx -> EthRpc1.eth_getTransactionReceipt? in
            assert(cdTx.ethTxHash != nil)
            assert(cdTx.status != nil)

            guard let ethTxHash = cdTx.ethTxHash else { return nil }

            let txHashData: Data = Data(hex: ethTxHash)
            let txHashEthData = EthRpc1.Data(Eth.Hash(txHashData))
            let getReceiptMethod = EthRpc1.eth_getTransactionReceipt(transactionHash: txHashEthData)

            return getReceiptMethod
        }

        guard !rpcMethods.isEmpty else {
            return
        }

        let methodById: [JsonRpc2.Id: EthRpc1.eth_getTransactionReceipt] = Dictionary(
            uniqueKeysWithValues: rpcMethods.enumerated().map { (JsonRpc2.Id.int($0.offset), $0.element) }
        )

        // send requests to the node
        let batchRequest: JsonRpc2.BatchRequest

        do {
            batchRequest = try JsonRpc2.BatchRequest(
                requests: methodById.map { try $0.value.request(id: $0.key) }
            )
        } catch {
            LogService.shared.debug("Transaction monitor [chain=\(chainId)]: failed to create batch request: \(error)")
            return
        }

        // the core data objects might change while we're making the network request
        // therefore we need to remember the data that will tell us that we still should udpate the objects
        // after network request is completed.
        //
        // patch: using array instead of a dictionary (by tx hash) because of duplicate entries in the database
        let cdTxByTxHash: [(txHash: String, status: String, updatedAt: Date?, ethTx: CDEthTransaction)] =
            cdEthTransactions.map { ($0.ethTxHash!, $0.status!, $0.dateUpdatedAt, $0) }

        // send the batch request
        self.queryTask?.cancel()
        self.queryTask = client.send(request: batchRequest) { [weak self] batchResponse in
            guard self != nil else {
                return
            }

            switch batchResponse {
            case .none:
                LogService.shared.debug("Transaction monitor [chain=\(chainId)]: did not receive any batch resposne")
                return

            case .response(let response):
                LogService.shared.debug("Transaction monitor [chain=\(chainId)]: received unexpected response: \(response)")
                return

            case .array(let responses):
                // convert the responses to the receipt results

                let receipts: [EthRpc1.ReceiptInfo]

                do {
                    receipts = try responses.compactMap { response -> EthRpc1.ReceiptInfo? in
                        guard let method = methodById[response.id] else { return nil }
                        if let error = response.error {
                            LogService.shared.debug("Transaction monitor [chain=\(chainId)]: error getting receipt \(method) \(response) \(error)")
                            return nil
                        }
                        guard let result = response.result else { return nil }
                        let receipt = try method.result(from: result)
                        return receipt
                    }
                } catch {
                    LogService.shared.debug("Transaction monitor [chain=\(chainId)]: error transforming receipts: \(error)")
                    return
                }

                DispatchQueue.main.async { [weak self] in
                    // only notify if there are any updates
                    var shouldNotifyTransactionObservers = false
                    var updatedTxCount = 0

                    // update the transactions based on the receipt results
                    for receipt in receipts {

                        // check for cancellation of the task
                        guard self != nil else {
                            LogService.shared.debug("Transaction monitor [chain=\(chainId)]: cancelled")
                            App.shared.coreDataStack.rollback()
                            return
                        }

                        // match by receipt tx hash
                        guard let cdTxData = cdTxByTxHash.first(where: { $0.txHash == receipt.transactionHash}) else { continue }

                        // check if the transaction status is still unchanged
                        guard cdTxData.status == cdTxData.ethTx.status, cdTxData.updatedAt == cdTxData.updatedAt else {
                            // otherwise we detected that the object changed during the network request
                            // so we skip the result
                            continue
                        }

                        // now update the data with the receipt results
                        if receipt.status == "0x0" {
                            // transaction failed
                            cdTxData.ethTx.status = SCGModels.TxStatus.awaitingExecution.rawValue
                            cdTxData.ethTx.dateExecutedAt = Date()
                        } else if receipt.status == "0x1" {
                            // successful
                            cdTxData.ethTx.status = SCGModels.TxStatus.success.rawValue
                            cdTxData.ethTx.dateExecutedAt = Date()
                        } else {
                            // unrecognized status, do nothing
                        }

                        cdTxData.ethTx.dateUpdatedAt = Date()
                        shouldNotifyTransactionObservers = true
                        updatedTxCount += 1

                    }

                    // check for cancellation of the task
                    guard self != nil else {
                        LogService.shared.debug("Transaction monitor [chain=\(chainId)]: cancelled")
                        App.shared.coreDataStack.rollback()
                        return
                    }

                    // save all of the changes made
                    App.shared.coreDataStack.saveContext()

                    if shouldNotifyTransactionObservers {
                        // Notify the observers about tx changes
                        NotificationCenter.default.post(name: .transactionDataInvalidated, object: nil)
                        LogService.shared.debug("Transaction monitor [chain=\(chainId)]: updated \(updatedTxCount) transaction(s)")
                    } else {
                        LogService.shared.debug("Transaction monitor [chain=\(chainId)]: found no updates from servers")
                    }
                }
            }
        }
    }
}
