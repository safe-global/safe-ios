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

    static let safeCreationTimeout: TimeInterval = 24 * 60 * 60

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
        NotificationCenter.default.addObserver(self, selector: #selector(updateDeployingSafes), name: .transactionDataInvalidated, object: nil)
    }

    let clientGateway = App.shared.clientGatewayService

    @objc func updateDeployingSafes() {
        let deployingSafes = Safe.all.filter { safe in safe.safeStatus == .deploying }

        deployingSafes.forEach { safe in
            guard let tx = CDEthTransaction.by(safeAddresses: [safe.address!], chainId: safe.chain!.id!).first,
                  let statusString = tx.status,
                  let status = SCGModels.TxStatus(rawValue: statusString)
            else { return }
            switch status {
            case .success:
                safe.safeStatus = .indexing

            case .pending:
                if let date = tx.dateSubmittedAt, Date().timeIntervalSince(date) >= Self.safeCreationTimeout {
                    fallthrough
                }
            default:
                break
            }
        }

        App.shared.coreDataStack.saveContext()
    }

    func querySafeInfo() {
        updateDeployingSafes()

        let indexing = Safe.all.filter { safe in safe.safeStatus == .indexing }

        indexing.forEach { safe in
            _ = clientGateway.asyncSafeInfo(safeAddress: safe.addressValue,
                                               chainId: safe.chain!.id!) { [weak self] result in
                DispatchQueue.main.async { [weak self] in
                    switch result {
                    case .failure(_):
                        break
                    case .success(let info):
                        safe.safeStatus = .deployed
                        safe.update(from: info)
                        App.shared.coreDataStack.saveContext()
                        NotificationCenter.default.post(name: .safeCreationUpdate,
                                                        object: self,
                                                        userInfo: ["chain": safe.chain!,
                                                                   "safe": safe,
                                                                   "success": true])
                    }
                }
            }
        }
    }
}
