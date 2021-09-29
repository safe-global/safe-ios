//
//  WalletConnectSafesServerController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 08.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

class WalletConnectSafesServerController: WalletConnectServerController {
    static let shared = WalletConnectSafesServerController()

    override init() {
        super.init()
        
        server.register(handler: WCRequestsHandler(server: server))

        connectingNotification = .wcConnectingSafeServer
        disconnectingNotification = .wcDidDisconnectSafeServer
        didFailToConnectNotificatoin = .wcDidFailToConnectSafeServer
        didConnectNotificatoin = .wcDidConnectSafeServer
        didDisconnectNotificatoin = .wcDidDisconnectSafeServer
    }

    override func createSession(wcurl: WCURL) {
        WCSession.create(wcurl: wcurl)
    }

    override func getSession(topic: String) -> Session? {
        guard let wcSession = WCSession.get(topic: topic) else { return nil }
        do {
            return try Session.from(wcSession)
        } catch {
            wcSession.delete()
            return nil
        }
    }

    override func deleteStoredSession(topic: String) {
        precondition(Thread.isMainThread)
        guard let wcSession = WCSession.get(topic: topic) else { return }
        wcSession.delete()
    }

    override func update(session: Session, status: SessionStatus) {
        precondition(Thread.isMainThread)
        WCSession.update(session: session, status: status)
    }

    override func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        let walletMeta = Session.ClientMeta(name: "Gnosis Safe",
                                            description: "The most trusted platform to manage digital assets.",
                                            icons: [URL(string: "https://gnosis-safe.io/app/favicon.ico")!],
                                            url: URL(string: "https://gnosis-safe.io")!)

        guard let safe = try? Safe.getSelected(),
              let address = safe.address,
              let chain = safe.chain
        else {
            // we can't get address or network in the local database, we're closing connection.
            denySession(clientMeta: walletMeta, displayMessage: nil, completion: completion)
            return
        }

        // Right now WalletConnect library expects chainId to be Int type.
        guard let selectedSafeChainId = Int(chain.id!) else {
            denySession(clientMeta: walletMeta,
                        displayMessage: "Selected safe chain is not supported yet.",
                        completion: completion)
            return
        }

        let walletInfo = Session.WalletInfo(
            approved: true,
            accounts: [address],
            chainId: selectedSafeChainId,
            peerId: UUID().uuidString,
            peerMeta: walletMeta)

        completion(walletInfo)
    }

    func reconnectAllSessions() {
        guard let wcSessions = try? WCSession.getAll() else { return }

        wcSessions.forEach {
            guard $0.session != nil, let session = try? Session.from($0) else {
                // Trying to reconnect a session without handshake process finished.
                // This could happed when the app restarts in the middle of the process.
                $0.delete()
                return
            }

            try! server.reconnect(to: session)
        }
    }
}
