//
// Created by Vitaly on 17.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation


class WebConnectionExpirationMonitor {
    static var globalTimer: Timer?
    static let shared = WebConnectionExpirationMonitor()

    static func scheduleMonitoring(repeatInterval: TimeInterval = 60, runImmediately: Bool = true) {
        globalTimer?.invalidate()

        globalTimer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true, block: { _ in
            Self.shared.checkConnections()
        })

        if runImmediately {
            Self.shared.checkConnections()
        }
    }

    static func stopMonitoring() {
        globalTimer?.invalidate()
    }

    private var controller: WebConnectionController = WebConnectionController.shared

    func checkConnections() {

        let now = Date()

        let connections = controller.connections()
        for connection in connections {
            if let expirationDate = connection.expirationDate, expirationDate <= now {
                cleanUpConnection(connection)
            }
        }
    }

    private func cleanUpConnection(_ connection: WebConnection) {
        controller.delete(connection)
    }
}
