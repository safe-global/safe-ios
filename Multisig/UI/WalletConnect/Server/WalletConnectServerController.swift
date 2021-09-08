//
//  WalletConnectServerController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

class WalletConnectServerController: ServerDelegate {
    private(set) var server: Server!
    private let notificationCenter = NotificationCenter.default
    private var showedNotificationsSessionTopics = [String]()

    // Subclasses should override
    var connectingNotification: NSNotification.Name!
    var disconnectingNotification: NSNotification.Name!
    var didFailToConnectNotificatoin: NSNotification.Name!
    var didConnectNotificatoin: NSNotification.Name!
    var didDisconnectNotificatoin: NSNotification.Name!
    startLoading
    init() {
        server = Server(delegate: self)
        server.register(handler: WCRequestsHandler(server: server))
    }

    func connect(url: String) throws {
        guard let wcurl = WCURL(url) else { throw GSError.InvalidWalletConnectQRCode() }
        do {
            createSession(wcurl: wcurl)
            try server.connect(to: wcurl)
            notificationCenter.post(name: connectingNotification, object: wcurl)
        } catch {
            throw GSError.CouldNotStartWallectConnectSession()
        }
    }

    func createSession(wcurl: WCURL) {
        preconditionFailure("Subclass should override createSession method")
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

    func disconnect(topic: String) {
        guard let wcSession = WCSession.get(topic: topic) else { return }
        do {
            try server.disconnect(from: try Session.from(wcSession))
        } catch {
            wcSession.delete()
            notificationCenter.post(name: disconnectingNotification, object: nil)
        }
    }

    func sessions(for address: Address) -> [Session] {
        guard let wcSessions = try? WCSession.getAll() else { return [] }

        var sessions = [Session]()
        for wcSession in wcSessions {
            do {
                sessions.append(try Session.from(wcSession))
            } catch {
                wcSession.delete()
            }
        }

        return sessions
    }

    // MARK: - ServerDelegate

    func server(_ server: Server, didFailToConnect url: WCURL) {
        DispatchQueue.main.sync {
            guard let wcSession = WCSession.get(topic: url.topic) else { return }
            wcSession.delete()
        }
        notificationCenter.post(name: didFailToConnectNotificatoin, object: url)
    }

    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        preconditionFailure("Subclass should override createSession method")
    }

    #warning("TODO: make snackbar message display business of view controllers")
    func server(_ server: Server, didConnect session: Session) {
        DispatchQueue.main.sync {
            WCSession.update(session: session, status: .connected)
        }
        notificationCenter.post(name: didConnectNotificatoin, object: session)

        // skip snackbar notification for reconnect cases
        if !showedNotificationsSessionTopics.contains(session.url.topic) {
            showedNotificationsSessionTopics.append(session.url.topic)
            DispatchQueue.main.async {
                App.shared.snackbar.show(message: "WalletConnect session created! Please return back to the browser.")
            }
        }
    }

    func server(_ server: Server, didDisconnect session: Session) {
        DispatchQueue.main.sync {
            guard let wcSession = WCSession.get(topic: session.url.topic) else { return }
            wcSession.delete()
        }
        notificationCenter.post(name: didDisconnectNotificatoin, object: session)
    }

    func server(_ server: Server, didUpdate session: Session) {
        DispatchQueue.main.sync {
            WCSession.update(session: session, status: .connected)
        }
    }

    func denySession(clientMeta: Session.ClientMeta,
                             displayMessage: String? ,
                             completion: (Session.WalletInfo) -> Void) {
        let walletInfo = Session.WalletInfo(
            approved: false,
            accounts: [],
            chainId: Int(Chain.ChainID.ethereumMainnet)!,
            peerId: UUID().uuidString,
            peerMeta: clientMeta)

        if let displayMessage = displayMessage {
            DispatchQueue.main.async {
                App.shared.snackbar.show(message: displayMessage)
            }
        }

        completion(walletInfo)
    }
}
