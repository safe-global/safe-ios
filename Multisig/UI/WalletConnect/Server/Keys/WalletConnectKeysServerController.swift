//
//  WalletConnectKeysServerController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 08.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

protocol WalletConnectKeysServerControllerDelegate: AnyObject {
    func shouldStart(session: Session, completion: @escaping ([KeyInfo]) -> Void)
}

class WalletConnectKeysServerController: WalletConnectServerController {
    static let shared = WalletConnectKeysServerController()

    weak var delegate: WalletConnectKeysServerControllerDelegate?

    override init() {
        super.init()

        server.register(handler: WCKeysRequestsHandler(server: server))

        connectingNotification = .wcConnectingKeyServer
        disconnectingNotification = .wcDidDisconnectKeyServer
        didFailToConnectNotificatoin = .wcDidFailToConnectKeyServer
        didConnectNotificatoin = .wcDidConnectKeyServer
        didDisconnectNotificatoin = .wcDidDisconnectKeyServer
    }

    override func createSession(wcurl: WCURL) {
        WCKeySession.create(wcurl: wcurl)
    }

    override func getSession(topic: String) -> Session? {
        guard let wcKeySession = WCKeySession.get(topic: topic) else { return nil }
        do {
            return try Session.from(wcKeySession)
        } catch {
            wcKeySession.delete()
            return nil
        }
    }

    override func deleteStoredSession(topic: String) {
        precondition(Thread.isMainThread)
        guard let wcKeySession = WCKeySession.get(topic: topic) else { return }
        wcKeySession.delete()
    }

    override func update(session: Session, status: SessionStatus) {
        precondition(Thread.isMainThread)
        WCKeySession.update(session: session, status: status)
    }

    override func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        delegate?.shouldStart(session: session) { [unowned self] keys in
            let keysMeta = Session.ClientMeta(name: "Gnosis Safe Keys",
                                              description: "Your Safe owner keys.",
                                              icons: [URL(string: "https://gnosis-safe.io/app/favicon.ico")!],
                                              url: URL(string: "https://gnosis-safe.io")!)

            guard !keys.isEmpty else {
                self.denySession(clientMeta: keysMeta, displayMessage: nil, completion: completion)
                return
            }

            let chainId = session.dAppInfo.chainId ?? Int(Chain.ChainID.ethereumMainnet)!

            let keysInfo = Session.WalletInfo(
                approved: true,
                accounts: keys.map { $0.address.checksummed },
                chainId: chainId,
                peerId: UUID().uuidString,
                peerMeta: keysMeta)

            completion(keysInfo)
        }
    }

    func reconnectAllSessions() {
        guard let wcKeySessions = try? WCKeySession.getAll() else { return }

        wcKeySessions.forEach {
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
