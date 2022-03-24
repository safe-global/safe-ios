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

class WalletConnectClientController {
    static let shared = WalletConnectClientController()

    // We use specific key prefix to identify that this is our connection URL
    // and not to connect to if it is in the Pasteboard on entering foreground
    static let safeKeyPrefix = "gnosissafe".data(using: .utf8)!.toHexString()

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

        let key = randomKey()!.replacingCharacters(in: ..<Self.safeKeyPrefix.endIndex, with: Self.safeKeyPrefix)
        let wcUrl =  WCURL(topic: UUID().uuidString,
                           bridgeURL: App.configuration.walletConnect.bridgeURL,
                           key: key)
        LogService.shared.info("WalletConnect Client URL: \(wcUrl.absoluteString)")

        let clientMeta = Session.ClientMeta(
            name: "Gnosis Safe",
            description: "The most trusted platform to manage digital assets on Ethereum",
            icons: [URL(string: "https://gnosis-safe.io/app/favicon.ico")!],
            url: URL(string: "https://gnosis-safe.io")!,
            scheme: "gnosissafe")

        var chainId: Int?
        if let networkChainId = try? Safe.getSelected()?.chain?.id {
            chainId = Int(networkChainId)
        }
        
        let dAppInfo = Session.DAppInfo(peerId: UUID().uuidString, peerMeta: clientMeta, chainId: chainId)
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
    func connectToWallet(link: String) throws -> (topic: String, connectionURL: URL) {
        let wcUrl = try connect()
        let uri = wcUrl.fullyPercentEncodedStr
        var delimiter: String
        if link.contains("http") {
            delimiter = "/"
        } else {
            delimiter = "//"
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

    func sign(transaction: Transaction, completion: @escaping (String?) -> Void) {
        wcSign(transaction: transaction) { result in
            switch result {
            case .success(let signature):
                completion(signature)

            case .failure(_):
                completion(nil)
            }
        }
    }

    func sign(message: String, completion: @escaping (String?) -> Void) {
        wcSign(message: message) { result in
            switch result {
            case .success(let signature):
                completion(signature)

            case .failure(_):
                completion(nil)
            }
        }
    }

    func send(transaction: Client.Transaction, completion: @escaping (String?) -> Void) {
        guard let session = session,
              let client = client
        else {
            dispatchOnMainThread(completion(nil))
            return
        }
        do {
            try client.eth_sendTransaction(url: session.url, transaction: transaction, completion: { response in
                
                let txHash: String?
                do {
                    txHash = try response.result(as: HashString.self).description
                } catch {
                    txHash = nil
                }
                
                dispatchOnMainThread(completion(txHash))
            })
        } catch {
            dispatchOnMainThread(completion(nil))
        }
    }

    private func wcSign(transaction: Transaction, completion: @escaping (Result<String, Error>) -> Void) {
        guard let session = session,
              let client = client,
              let walletAddress = session.walletInfo?.accounts.first else {
            completion(.failure(GSError.WalletNotConnected(description: "Could not sign transaction")))
            return
        }

        do {
            switch session.walletInfo?.peerMeta.name ?? "" {
            // we call signTypedData only for wallets supporting this feature
            case "MetaMask", "LedgerLive", "🌈 Rainbow", "Trust Wallet":
                let message = EIP712Transformer.typedDataString(from: transaction)
                try client.eth_signTypedData(url: session.url, account: walletAddress, message: message) { [weak self] in
                    self?.handleResponse($0, completion: completion)
                }

            default:
                let message = transaction.safeTxHash.description
                try client.eth_sign(url: session.url, account: walletAddress, message: message) { [weak self] in
                    self?.handleResponse($0, completion: completion)
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    // signs message without adding 'ethereum...' prefix to it.
    private func wcSign(message: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let session = session,
              let client = client,
              let walletAddress = session.walletInfo?.accounts.first else {
            completion(.failure(GSError.WalletNotConnected(description: "Could not sign transaction")))
            return
        }

        do {
            try client.eth_sign(url: session.url, account: walletAddress, message: message) { [weak self] in
                self?.handleResponse($0, completion: completion)
            }
        } catch {
            completion(.failure(error))
        }
    }

    private func handleResponse(_ response: Response, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            var signature = try response.result(as: String.self)

            var signatureBytes = Data(hex: signature).bytes
            var v = signatureBytes.last!
            if v < 27 {
                v += 27
                signatureBytes[signatureBytes.count - 1] = v
                signature = Data(signatureBytes).toHexStringWithPrefix()
            }

            completion(.success(signature))
        } catch {
            completion(.failure(error))
        }
    }

    // https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
    // used as a secret key for initiating new session
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
        if let installedWallet = keyInfo.installedWallet,
           let schemeUrl = URL(string: installedWallet.scheme),
           UIApplication.shared.canOpenURL(schemeUrl) {

            if !installedWallet.universalLink.isEmpty {
                // MetaMask shows error alert if nothing is provided to the link
                // https://github.com/MetaMask/metamask-mobile/blob/194a1858b96b1f88762f8679380b09dda3c8b29e/app/core/DeeplinkManager.js#L89
                UIApplication.shared.open(URL(string: installedWallet.universalLink.appending("/focus"))!)
            } else {
                UIApplication.shared.open(URL(string: installedWallet.scheme)!)
            }
        } else {
            App.shared.snackbar.show(message: "Please open your wallet to sign the transaction.")
        }
    }

    @discardableResult
    static func reconnectWithInstalledWallet(_ installedWallet: InstalledWallet) -> String? {
        do {
            let link = installedWallet.universalLink.isEmpty ? installedWallet.scheme : installedWallet.universalLink
            let (topic, connectionURL) = try WalletConnectClientController.shared.connectToWallet(link: link)

            // we need a delay so that WalletConnectClient can send handshake request
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
                UIApplication.shared.open(connectionURL, options: [:], completionHandler: nil)
            }

            return topic
        } catch {
            App.shared.snackbar.show(
                error: GSError.error(description: "Could not create connection URL", error: error))
        }

        return nil
    }

    static func showConnectionQRCodeController(from controller: UIViewController,
                                               completion: (Result<Void, Error>) -> Void) {

        // TODO: connect via qr code
//        do {
//            let connectionURI = try WalletConnectClientController.shared.connect().absoluteString
//            let qrCodeVC = WalletConnectQRCodeViewController.create(code: connectionURI)
//            controller.present(qrCodeVC, animated: true, completion: nil)
//            completion(.success(()))
//        } catch {
//            completion(.failure(error))
//        }
    }
}

// MARK: - ClientDelegate

extension WalletConnectClientController: ClientDelegate {
    func client(_ client: Client, didFailToConnect url: WCURL) {
        NotificationCenter.default.post(name: .wcDidFailToConnectClient, object: nil)
    }

    func client(_ client: Client, didConnect url: WCURL) {
        // no op
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

    func client(_ client: Client, didUpdate session: Session) {
        self.session = session
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

/// Different wallets might implemented different encoding styles
extension WCURL {
    var partiallyPercentEncodedStr: String {
        let params = "bridge=\(bridgeURL.absoluteString)&key=\(key)"
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        return "wc:\(topic)@\(version)?\(params))"
    }

    var fullyPercentEncodedStr: String {
        absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
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

extension Client.Transaction {
    static func from(address: String,
                     transaction: Transaction,
                     rpcURL: URL,
                     confirmations: [SCGModels.Confirmation],
                     confirmationsRequired: UInt64,
                     nonce: String,
                     gas: String? = nil,
                     gasPrice: String? = nil) -> Client.Transaction {

        Client.Transaction(
            from: address,
            to: transaction.safe!.description,
            data: SafeContract(rpcURL: rpcURL).execTransaction(transaction,
                                                 confirmations: confirmations,
                                                 confirmationsRequired: confirmationsRequired).toHexStringWithPrefix(),
            gas: gas,
            gasPrice: gasPrice,
            value: nil,
            nonce: nonce,
            type: nil,
            accessList: nil,
            chainId: nil,
            maxPriorityFeePerGas: nil,
            maxFeePerGas: nil
        )
    }
}
