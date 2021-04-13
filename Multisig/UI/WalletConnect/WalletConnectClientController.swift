//
//  WalletConnectClientController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 13.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

#warning("Handle properly errors")
class WalletConnectClientController {
    static let shared = WalletConnectClientController()

    private var client: Client?
    private var session: Session? {
        didSet {
            if let session = session {
                clientSessionData = try! JSONEncoder().encode(session)
            } else {
                clientSessionData = nil
            }
        }
    }

    @UserDefault(key: "io.gnosis.multisig.wcClientSession")
    private var clientSessionData: Data?

    func connect() -> String {
        // gnosis wc bridge: https://safe-walletconnect.gnosis.io
        // test bridge with latest protocol version: https://bridge.walletconnect.org
        let wcUrl =  WCURL(topic: UUID().uuidString,
                           bridgeURL: URL(string: "https://safe-walletconnect.gnosis.io")!,
                           key: randomKey()!)
        LogService.shared.info("WalletConnect Client URL: \(wcUrl.absoluteString)")

        let clientMeta = Session.ClientMeta(name: "Gnosis Safe Multisig",
                                            description: "The most trusted platform to manage digital assets on Ethereum",
                                            icons: [URL(string: "https://gnosis-safe.io/app/favicon.ico")!],
                                            url: URL(string: "https://gnosis-safe.io")!,
                                            scheme: "gnosissafe")
        let dAppInfo = Session.DAppInfo(peerId: UUID().uuidString, peerMeta: clientMeta)
        client = Client(delegate: self, dAppInfo: dAppInfo)

        do {
            try client!.connect(to: wcUrl)
        } catch {
            LogService.shared.debug("Error connecting WC client: \(error.localizedDescription)")
        }

        return wcUrl.absoluteString
    }

    func reconnectIfNeeded() {
        guard session == nil else { return }
        if let clientSessionData = clientSessionData,
            let session = try? JSONDecoder().decode(Session.self, from: clientSessionData) {
            self.client = Client(delegate: self, dAppInfo: session.dAppInfo)
            do {
                try client!.reconnect(to: session)
            } catch {
                self.clientSessionData = nil
                LogService.shared.debug("Error reconnecting WC client: \(error.localizedDescription)")
            }
        }
    }

    func disconnect() {
        guard let client = client, let session = session else { return }
        do {
            try client.disconnect(from: session)
        } catch {
            LogService.shared.debug("Error disconnecting WC client: \(error.localizedDescription)")
        }
    }

    // https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
    private func randomKey() -> String? {
        var bytes = [Int8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return Data(bytes: bytes, count: 32).toHexString()
        } else {
            return nil
        }
    }
}

extension WalletConnectClientController: ClientDelegate {
    func client(_ client: Client, didFailToConnect url: WCURL) {
        self.session = nil
        NotificationCenter.default.post(name: .wcDidFailToConnectClient, object: nil)
    }

    func client(_ client: Client, didConnect session: Session) {
        self.session = session
        NotificationCenter.default.post(name: .wcDidConnectClient, object: nil)
    }

    func client(_ client: Client, didDisconnect session: Session) {
        self.session = nil
        NotificationCenter.default.post(name: .wcDidDisconnectClient, object: nil)
    }
}
