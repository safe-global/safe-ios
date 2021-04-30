//
//  WalletConnectClientController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 13.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import WalletConnectSwift

#warning("Handle properly errors")
class WalletConnectClientController {
    static let shared = WalletConnectClientController()

    private var client: Client?
    private var session: Session? {
        didSet {
            if let session = session {
                clientSessionData = session.data
            } else {
                clientSessionData = nil
            }
        }
    }

    @UserDefault(key: "io.gnosis.multisig.wcClientSession")
    private var clientSessionData: Data?

    func connect() throws -> WCURL {
        // Currently controller supports only one session at the time.
        disconnect()

        // gnosis wc bridge: https://safe-walletconnect.gnosis.io
        // zerion wc bridge: https://wcbridge.zerion.io
        // test bridge with latest protocol version: https://bridge.walletconnect.org
        let wcUrl =  WCURL(topic: UUID().uuidString,
                           bridgeURL: URL(string: "https://wcbridge.zerion.io")!,
                           key: randomKey()!)
        LogService.shared.info("WalletConnect Client URL: \(wcUrl.absoluteString)")

        let clientMeta = Session.ClientMeta(
            name: "Gnosis Safe Multisig",
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
            throw GSError.CouldNotCreateWallectConnectURL()
        }

        return wcUrl
    }

    /// https://docs.walletconnect.org/mobile-linking#for-ios
    func getTopicAndConnectionURL(universalLink: String) throws -> (String, URL) {
        let wcUrl = try connect()
        let urlStr = "\(universalLink)/wc?uri=\(wcUrl.urlEncodedStr)"
        return (wcUrl.topic, URL(string: urlStr)!)
    }

    func reconnectIfNeeded() {
        guard session == nil else { return }
        if let clientSessionData = clientSessionData,
            let session = try? JSONDecoder().decode(Session.self, from: clientSessionData) {
            self.client = Client(delegate: self, dAppInfo: session.dAppInfo)

            // this call may throw only `missingWalletInfoInSession` error that would be a developer error
            try! client!.reconnect(to: session)
        }
    }

    func disconnect() {
        guard let client = client, let session = session else { return }
        do {
            try client.disconnect(from: session)
            // remove cached data immediately
            clientSessionData = nil
        } catch {
            // we ignore disconnect errors
            LogService.shared.debug("Error disconnecting WC client: \(error.localizedDescription)")
        }
    }

    /// Checks if active session's wallet peerId equal with provided to the method
    /// - Parameter peerId: WalletInfo.peerId
    /// - Returns: true is wallet with `peerId` is connected
    func isConnected(peerId: String) -> Bool {
        return session?.walletInfo?.peerId == peerId
    }

    func sign(message: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let session = session,
              let client = client,
              let walletAddress = session.walletInfo?.accounts.first else {
            // TODO: use GSError
            completion(.failure("Failed to sign: wallet not connected. Please connect your wallet."))
            return
        }

        do {
            try client.eth_sign(url: session.url, account: walletAddress, message: message) { response in
                do {
                    let signature = try response.result(as: String.self)
                    completion(.success(signature))
                } catch {
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func sign(message: String, from controller: UIViewController, completion: @escaping (String) -> Void) {
        guard controller.presentedViewController == nil else { return }

        let pendingConfirmationVC = WCPedingConfirmationViewController()
        pendingConfirmationVC.modalPresentationStyle = .overCurrentContext
        controller.present(pendingConfirmationVC, animated: false)

        sign(message: message) { result in
            switch result {
            case .success(let signature):
                DispatchQueue.main.async {
                    // dismiss pending confirmation view controller overlay
                    controller.dismiss(animated: false, completion: nil)
                }
                completion(signature)

            case .failure(_):
                DispatchQueue.main.async {
                    // dismiss pending confirmation view controller overlay
                    controller.dismiss(animated: false, completion: nil)
                    App.shared.snackbar.show(error: GSError.CouldNotSignWithWalletConnect())
                }
            }
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

// MARK: - ClientDelegate

extension WalletConnectClientController: ClientDelegate {
    func client(_ client: Client, didFailToConnect url: WCURL) {
        NotificationCenter.default.post(name: .wcDidFailToConnectClient, object: nil)
    }

    func client(_ client: Client, didConnect session: Session) {
        self.session = session
        NotificationCenter.default.post(name: .wcDidConnectClient, object: session)
    }

    func client(_ client: Client, didDisconnect session: Session) {
        // ignore notifications for old sessions
        guard isActiveSession(session) else { return }
        self.session = nil
        NotificationCenter.default.post(name: .wcDidDisconnectClient, object: nil)
    }

    private func isActiveSession(_ session: Session) -> Bool {
        return self.session?.dAppInfo.peerId == session.dAppInfo.peerId
    }
}

// MARK: - WalletConnectClientController + KeyInfo

extension WalletConnectClientController {
    func isConnected(keyInfo: KeyInfo) -> Bool {
        guard let metadata = keyInfo.metadata,
              let walletMetadata = KeyInfo.WalletConnectKeyMetadata.from(data: metadata) else {
            return false
        }
        return isConnected(peerId: walletMetadata.walletInfo.peerId)
    }
}

// MARK: - WalletConnectSwift + Extension

extension WCURL {
    var urlEncodedStr: String {
        let params = "bridge=\(bridgeURL.absoluteString)&key=\(key)"
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        return "wc:\(topic)@\(version)?\(params))"
    }
}

extension Session {
    var data: Data {
        try! JSONEncoder().encode(self)
    }

    static func from(data: Data) -> Self? {
        try? JSONDecoder().decode(Self.self, from: data)
    }
}
