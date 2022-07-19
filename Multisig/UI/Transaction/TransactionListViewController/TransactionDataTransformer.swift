//
//  TransactionDataTransformer.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

// enhances the client gateway transaction data with the local data to display correct transaction status.
class TransactionDataTransformer {

    let safe: Safe
    let chain: Chain

    init(safe: Safe, chain: Chain) {
        self.safe = safe
        self.chain = chain
        assert(safe.address != nil)
        assert(chain.id != nil)
    }

    func transformed(list: [SCGModels.TransactionSummaryItem]) -> [SCGModels.TransactionSummaryItem] {
        assert(Thread.isMainThread)

        let localTxs = localData(safeAddress: safe.address!, chainId: chain.id!)

        guard !localTxs.isEmpty else { return list }

        var hasDatabaseChanges: Bool = false

        let result = list.map { item -> SCGModels.TransactionSummaryItem in
            switch item {
            case .transaction(let txItem):
                // find local matching transaction

                // FIXME: this will break when the backend id schema will change! Instead we need info from the backend.
                let idParts = txItem.transaction.id.split(separator: "_")
                guard idParts.count == 3, let safeTxHash = idParts.last.map(String.init), !safeTxHash.isEmpty else {
                    return item
                }

                guard let localTx = localTxs.first(where: { $0.safeTxHash == safeTxHash }) else {
                    return item
                }

                guard let localRawStatus = localTx.status, let localStatus = SCGModels.TxStatus(rawValue: localRawStatus) else {
                    return item
                }

                // compute status updates

                var txItem = txItem
                switch (txItem.transaction.txStatus, localStatus) {
                case (.awaitingExecution, .pending):
                    // assume the safe tx not minded yet
                    txItem.transaction.txStatus = .pending

                case (.awaitingExecution, .awaitingExecution):
                    // show that execution attempt failed
                    txItem.transaction.txStatus = .awaitingExecution

                case (.awaitingExecution, .success):
                    // tx was mined but the backend hasn't updated yet. Keep it pending.
                    txItem.transaction.txStatus = .pending

                case (.success, .pending):
                    // backend got success status earlier than local data updated, get the value from backend data
                    localTx.status = SCGModels.TxStatus.success.rawValue
                    hasDatabaseChanges = true

                case (.failed, .pending):
                    // backend got failed status earlier than local data updated, get the value from backend data
                    localTx.status = SCGModels.TxStatus.failed.rawValue
                    hasDatabaseChanges = true

                default:
                    break
                }

                return .transaction(txItem)
            default:
                return item
            }
        }

        if hasDatabaseChanges {
            App.shared.coreDataStack.saveContext()
        }

        return result
    }

    func localData(safeAddress: String, chainId: String) -> [CDEthTransaction] {
        let context = App.shared.coreDataStack.viewContext

        let fetchRequest = CDEthTransaction.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "dateUpdatedAt", ascending: false)
        ]

        fetchRequest.predicate = NSPredicate(format: "safeAddress like[c] %@ AND chainId == %@",
                                             safeAddress, chainId)

        let cdEthTransactions: [CDEthTransaction]

        do {
            cdEthTransactions = try context.fetch(fetchRequest)
        } catch {
            return []
        }

        return cdEthTransactions
    }


    func transformed(transaction: SCGModels.TransactionDetails) -> SCGModels.TransactionDetails {
        guard let safeTxHash = transaction.multisigInfo?.safeTxHash, !safeTxHash.description.isEmpty else {
            return transaction
        }

        guard let localTx = localTransaction(safeAddress: safe.address!, chainId: chain.id!, safeTxHash: safeTxHash.description) else {
            return transaction
        }

        guard let localRawStatus = localTx.status, let localStatus = SCGModels.TxStatus(rawValue: localRawStatus) else {
            return transaction
        }
        var hasDatabaseChanges = false

        var transaction = transaction
        switch (transaction.txStatus, localStatus) {
        case (.awaitingExecution, .pending):
            // assume the safe tx not minded yet
            transaction.txStatus = .pending
            transaction.txHash = localTx.ethTxHash.map(DataString.init(hex:))

        case (.awaitingExecution, .success):
            // tx was mined but the backend hasn't updated yet. Keep it pending.
            transaction.txStatus = .pending
            transaction.txHash = localTx.ethTxHash.map(DataString.init(hex:))

        case (.success, .pending):
            // backend got success status earlier than local data updated, get the value from backend data
            localTx.status = SCGModels.TxStatus.success.rawValue
            hasDatabaseChanges = true

        case (.failed, .pending):
            // backend got success status earlier than local data updated, get the value from backend data
            localTx.status = SCGModels.TxStatus.failed.rawValue
            hasDatabaseChanges = true

        default:
            break
        }

        if hasDatabaseChanges {
            App.shared.coreDataStack.saveContext()
        }

        return transaction
    }

    func localTransaction(safeAddress: String, chainId: String, safeTxHash: String) -> CDEthTransaction? {
        let context = App.shared.coreDataStack.viewContext

        let fetchRequest = CDEthTransaction.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "dateUpdatedAt", ascending: false)
        ]
        fetchRequest.fetchLimit = 1

        fetchRequest.predicate = NSPredicate(format: "safeAddress like[c] %@ AND chainId == %@ AND safeTxHash like[c] %@",
                                             safeAddress, chainId, safeTxHash)

        let cdEthTransactions: [CDEthTransaction]

        do {
            cdEthTransactions = try context.fetch(fetchRequest)
        } catch {
            return nil
        }

        return cdEthTransactions.first

    }

}
