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
    }

    func connect(url: String) throws {
        guard let wcurl = WCURL(url) else { throw GSError.InvalidWalletConnectQRCode() }
        do {
            try server.connect(to: wcurl)
        } catch {
            throw GSError.CouldNotStartWallectConnectSession()
        }
    }

    func sessions(for safe: Address) -> [Session] {
        guard let wcSessions = try? WCSession.getAll() else { return [] }

        let decoder = JSONDecoder()
        var sessions = [Session]()
        for wcSession in wcSessions {
            do {
                let session = try decoder.decode(Session.self, from: wcSession.session!)
                sessions.append(session)
            } catch {
                WCSession.remove(peerId: wcSession.peerId!)
            }
        }

        return sessions
    }
}

extension WalletConnectController: ServerDelegate {
    func server(_ server: Server, didFailToConnect url: WCURL) {
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
        WCSession.create(session: session)
        notificationCenter.post(name: .wcDidConnect, object: session)
    }

    func server(_ server: Server, didDisconnect session: Session) {
        WCSession.remove(peerId: session.dAppInfo.peerId)
        notificationCenter.post(name: .wcDidDisconnect, object: session)
    }
}
