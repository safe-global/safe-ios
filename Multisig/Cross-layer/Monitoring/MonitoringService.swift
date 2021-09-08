//
//  MonitoringService.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 04.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class MonitoringService {
    static let shared = MonitoringService()

    private var syncLoopRepeater: Repeater?
    private let syncInterval: TimeInterval

    init(syncInterval: TimeInterval = 5) {
        self.syncInterval = syncInterval
    }

    /// Starts synchronisation loop on a background thread. Every `syncInterval` seconds the loop executes
    /// If inbetween of these udpates the synchronisation is stopped, then all further actions are skipped.
    func startMonitoring() {
        guard syncLoopRepeater == nil else { return }
        DispatchQueue.global().async { [unowned self] in
            // repeat syncronization loop every `syncInterval`
            self.syncLoopRepeater = Repeater(delay: self.syncInterval) { repeater in
                if repeater.isStopped { return }
                WalletConnectSafesServerController.shared.updatePendingTransactions()
            }
            // blocks current thread until the repeater is not stopped.
            self.syncLoopRepeater!.start()
        }
    }

    /// Stops a synchronisation loop, if it is running in background.
    public func stopSyncLoop() {
        if let repeater = syncLoopRepeater {
            repeater.stop()
            syncLoopRepeater = nil
        }
    }
}
