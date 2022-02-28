//
//  SafeCreationMonitor.swift
//  Multisig
//
//  Created by Moaaz on 2/24/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class SafeCreationMonitor {
    static var globalTimer: Timer?
    static let shared = SafeCreationMonitor()

    static func scheduleMonitoring(repeatInterval: TimeInterval = 10, runImmediately: Bool = true) {
        globalTimer?.invalidate()

        globalTimer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true, block: { _ in
            Self.shared.querySafeInfo()
        })

        if runImmediately {
            Self.shared.querySafeInfo()
        }
    }

    static func stopMonitoring() {
        globalTimer?.invalidate()
    }

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(txDataInvalidationNotificationReceived), name: .transactionDataInvalidated, object: nil)
    }

    let clientGateway = App.shared.clientGatewayService

    @objc func txDataInvalidationNotificationReceived() {
        let deployingSafes = Safe.all.filter { safe in safe.safeStatus == .deploying }

        deployingSafes.forEach { safe in
            guard let tx = CDEthTransaction.by(safeAddresses: [safe.address!], chainId: safe.chain!.id!)?.first,
                  let statusString = tx.status,
                  let status = SCGModels.TxStatus(rawValue: statusString)
            else { return }
            switch status {
            case .success:
                safe.safeStatus = .indexing
            case .pendingFailed:
                safe.safeStatus = .deploymentFailed
                NotificationCenter.default.post(name: .safeCreationUpdate, object: self, userInfo: ["safe" : safe,
                                                                                                    "success" : false,
                                                                                                    "txHash" : tx.ethTxHash,
                                                                                                    "chain" : safe.chain!])
            default:
                break
            }
        }

        App.shared.coreDataStack.saveContext()
    }

    func querySafeInfo() {
        let deployingSafes = Safe.all.filter { safe in safe.safeStatus == .indexing }

        deployingSafes.forEach { safe in
            clientGateway.asyncSafeInfo(safeAddress: safe.addressValue,
                                               chainId: safe.chain!.id!) { [weak self] result in
                DispatchQueue.main.async { [weak self] in
                    switch result {
                    case .failure(_):
                        break
                    case .success(_):
                        safe.safeStatus = .deployed
                        App.shared.coreDataStack.saveContext()
                        NotificationCenter.default.post(name: .safeCreationUpdate,
                                                        object: self,
                                                        userInfo: ["chain" : safe.chain!, "safe" : safe, "success" : true])
                    }
                }
            }
        }
    }
}
