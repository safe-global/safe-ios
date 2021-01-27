//
//  WalletConnectController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

class WalletConnectController {
    static let shared = WalletConnectController()
    private var server: Server!
    private let notificationCenter = NotificationCenter.default

    init() {
        server = Server(delegate: self)
        server.register(handler: WCRequestsHandler(server: server))
    }

    func connect(url: String) throws {
        guard let wcurl = WCURL(url) else { throw GSError.InvalidWalletConnectQRCode() }
        do {
            WCSession.create(wcurl: wcurl)
            try server.connect(to: wcurl)
            notificationCenter.post(name: .wcConnecting, object: wcurl)
        } catch {
            throw GSError.CouldNotStartWallectConnectSession()
        }
    }

    func reconnectAllSessions() {
        guard let wcSessions = try? WCSession.getAll() else { return }

        wcSessions.forEach {
            guard $0.session != nil, let session = try? Session.from($0) else {
                // Trying to reconnect a session without handshake process finished.
                // This could happed when the app restarts in the middle of the process.
                WCSession.remove(topic: $0.topic!)
                return
            }

            try! server.reconnect(to: session)
        }
    }

    func disconnect(topic: String) {
        guard let wcSession = WCSession.get(topic: topic) else { return }
        do {
            try server.disconnect(from: try Session.from(wcSession))
        } catch {
            WCSession.remove(topic: topic)
            notificationCenter.post(name: .wcDidDisconnect, object: nil)
        }
    }

    func sessions(for safe: Address) -> [Session] {
        guard let wcSessions = try? WCSession.getAll() else { return [] }

        var sessions = [Session]()
        for wcSession in wcSessions {
            do {
                sessions.append(try Session.from(wcSession))
            } catch {
                WCSession.remove(topic: wcSession.topic!)
            }
        }

        return sessions
    }
}

extension WalletConnectController: ServerDelegate {
    func server(_ server: Server, didFailToConnect url: WCURL) {
        DispatchQueue.main.sync {
            WCSession.remove(topic: url.topic)
        }
        notificationCenter.post(name: .wcDidFailToConnect, object: url)
    }

    #warning("Get the link to safe logo")
    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        guard let safe = try? Safe.getSelected(), let address = safe.address else { return }

        let walletMeta = Session.ClientMeta(name: "Gnosis Safe Multisig",
                                            description: "The most trusted platform to manage digital assets.",
                                            icons: [],
                                            url: URL(string: "https://safe.gnosis.io")!)
        let walletInfo = Session.WalletInfo(
            approved: true,
            accounts: [address],
            chainId: App.configuration.app.network.chainId,
            peerId: UUID().uuidString,
            peerMeta: walletMeta)

        completion(walletInfo)
    }

    func server(_ server: Server, didConnect session: Session) {
        DispatchQueue.main.sync {
            WCSession.update(session: session, status: .connected)
        }
        notificationCenter.post(name: .wcDidConnect, object: session)
    }

    func server(_ server: Server, didDisconnect session: Session) {
        DispatchQueue.main.sync {
            WCSession.remove(topic: session.url.topic)
        }
        notificationCenter.post(name: .wcDidDisconnect, object: session)
    }
}
