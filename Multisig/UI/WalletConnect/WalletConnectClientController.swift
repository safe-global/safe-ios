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

        // gnosis wc bridge: https://safe-walletconnect.gnosis.io/
        // zerion wc bridge: https://wcbridge.zerion.io
        // test bridge with latest protocol version: https://bridge.walletconnect.org
        let wcUrl =  WCURL(topic: UUID().uuidString,
                           bridgeURL: URL(string: "https://safe-walletconnect.gnosis.io/")!,
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
    func getTopicAndConnectionURL(link: String) throws -> (String, URL) {
        let wcUrl = try connect()
        var delimiter: String
        var uri: String
        if link.contains("http") {
            delimiter = "/"
            uri = wcUrl.urlEncodedStr
        } else {
            delimiter = "//"
            uri = wcUrl.absoluteString
        }
        let urlStr = "\(link)\(delimiter)wc?uri=\(uri)"
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
            NotificationCenter.default.post(name: .wcDidDisconnectClient, object: nil)
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

    #warning("TODO: handle closing modal manually")
    func sign(message: String, from controller: UIViewController, completion: @escaping (String) -> Void) {
        guard controller.presentedViewController == nil else { return }

        let pendingConfirmationVC = WCPedingConfirmationViewController.create()
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

    func execute(transaction: Transaction,
                 confirmations: [SCGModels.Confirmation],
                 confirmationsRequired: UInt64,
                 from controller: UIViewController,
                 onSend: @escaping (Result<Bool, Error>) -> Void,
                 onResult: @escaping (Result<HashString, Error>) -> Void) {
        guard controller.presentedViewController == nil else { return }

        let pendingConfirmationVC = WCPedingConfirmationViewController.create(headerText: "Pending Execution")
        pendingConfirmationVC.modalPresentationStyle = .overCurrentContext
        controller.present(pendingConfirmationVC, animated: false)

        guard let session = session,
              let client = client,
              let walletAddress = session.walletInfo?.accounts.first else {
            // TODO: use GSError
            onSend(.failure("Failed to execute: wallet not connected. Please connect your wallet."))
            return
        }

        DispatchQueue.global().async {
            do {
                let nonceResponse = try App.shared.nodeService.rawCall(
                    payload: Request.nonce(for: walletAddress, session: session).jsonString)
                let response = try Response(url: session.url, jsonString: nonceResponse)
                let nonce = try response.result(as: String.self)

                let clientTransaction = Client.Transaction.from(address: walletAddress,
                                                                transaction: transaction,
                                                                confirmations: confirmations,
                                                                confirmationsRequired: confirmationsRequired,
                                                                nonce: nonce)

                try client.eth_sendTransaction(url: session.url, transaction: clientTransaction) { response in
                    do {
                        let txHash = try response.result(as: HashString.self)
                        onResult(.success(txHash))
                    } catch {
                        onResult(.failure(error))
                    }
                }

                onSend(.success(true))
            } catch {
                onSend(.failure(error))
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

    static func openWalletIfInstalled(keyInfo: KeyInfo) {
        if let installedWallet = keyInfo.installedWallet {
            // MetaMask shows error alert if nothing is provided to the link
            // https://github.com/MetaMask/metamask-mobile/blob/194a1858b96b1f88762f8679380b09dda3c8b29e/app/core/DeeplinkManager.js#L89
            UIApplication.shared.open(URL(string: installedWallet.universalLink.appending("/focus"))!)
        } else {
            App.shared.snackbar.show(message: "Please open your wallet to submit the execution transaction.")
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

extension Request {
    static func nonce(for address: String, session: Session) -> Request {
        return .eth_getTransactionCount(url: session.url, account: address)
    }

    private static func eth_getTransactionCount(url: WCURL, account: String) -> Request {
        return try! Request(url: url, method: "eth_getTransactionCount", params: [account, "latest"])
    }
}

extension Client.Transaction {
    static func from(address: String,
                     transaction: Transaction,
                     confirmations: [SCGModels.Confirmation],
                     confirmationsRequired: UInt64,
                     nonce: String) -> Client.Transaction {
        Client.Transaction(
            from: address,
            to: transaction.safe!.description,
            data: SafeContract().execTransaction(transaction,
                                                 confirmations: confirmations,
                                                 confirmationsRequired: confirmationsRequired).toHexString(),
            gas: nil,
            gasPrice: nil,
            value: nil,
            nonce: nonce
        )
    }
}
