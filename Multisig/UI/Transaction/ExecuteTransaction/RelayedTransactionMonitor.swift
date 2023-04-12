//
//  RelayedTransactionMonitor.swift
//  Multisig
//
//  Created by Mouaz on 4/8/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

class RelayedTransactionMonitor {
    static var globalTimer: Timer?
    static let shared = RelayedTransactionMonitor()
    private let gelatoService = App.shared.gelatoRelayService

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
    }

    func queryTransactionStatuses() {
        let context = App.shared.coreDataStack.viewContext
        let statusPending = SCGModels.TxStatus.pending.rawValue

        let fetchRequest = CDEthTransaction.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "taskId != nil AND status == %@", statusPending)

        let cdEthTransactions: [CDEthTransaction]

        do {
            cdEthTransactions = try context.fetch(fetchRequest)
        } catch {
            LogService.shared.debug("Relayed transaction monitor: failed to fetch transactions: \(error)")
            return
        }

        guard !cdEthTransactions.isEmpty else { return }

        cdEthTransactions.forEach { cdTxData in
            guard let taskId = cdTxData.taskId else { return }
            _ = gelatoService.asyncStatus(taskId: taskId, completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .failure(_):
                        break
                    case .success(let status):
                        if let txHash = status.task.transactionHash, status.task.taskState == .success {
                            cdTxData.status = SCGModels.TxStatus.success.rawValue
                            cdTxData.ethTxHash = txHash
                            cdTxData.dateUpdatedAt = Date()
                            cdTxData.dateExecutedAt = Date()
                            App.shared.coreDataStack.saveContext()
                            NotificationCenter.default.post(name: .transactionDataInvalidated, object: nil)
                        } else if [RelayedTaskStatus.Status.cancelled, .reverted].contains(status.task.taskState) {
                            cdTxData.status = SCGModels.TxStatus.failed.rawValue
                            cdTxData.dateUpdatedAt = Date()
                            App.shared.coreDataStack.saveContext()
                            NotificationCenter.default.post(name: .transactionDataInvalidated, object: nil)
                        }
                    }
                }
            })
        }
    }
}
