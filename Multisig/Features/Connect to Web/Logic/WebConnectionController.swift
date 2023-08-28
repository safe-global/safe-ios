//
// Created by Dmitry Bespalov on 10.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift
import Ethereum
import Solidity

protocol WebConnectionObserver: AnyObject {
    func didUpdate(connection: WebConnection)
}

protocol WebConnectionSubject: AnyObject {
    func attach(observer: WebConnectionObserver, to connection: WebConnection)
    func detach(observer: WebConnectionObserver)
    func notifyObservers(of connection: WebConnection)
}

protocol WebConnectionListObserver: AnyObject {
    func didUpdateConnections()
}

protocol WebConnectionListSubject: AnyObject {
    func attach(observer: WebConnectionListObserver)
    func detach(observer: WebConnectionListObserver)
    func notifyListObservers()
}

protocol WebConnectionRequestObserver: AnyObject {
    func didUpdate(request: WebConnectionRequest)
}

protocol WebConnectionRequestSubject: AnyObject {
    func attach(observer: WebConnectionRequestObserver)
    func detach(observer: WebConnectionRequestObserver)
    func notifyObservers(of request: WebConnectionRequest)
}

protocol WebConnectionSingleRequestSubject: AnyObject {
    func attach(observer: WebConnectionRequestObserver, to request: WebConnectionRequest)
    func notifyObservers(of request: WebConnectionRequest)
}
/// Controller implementing the business-logic of managing connections and handling incoming requests.
///
/// Use the `shared` instance since the controller's lifetime is the same as the app's lifetime.
///
/// Remember to set the `delegate` in order to respond to connection events.
class WebConnectionController: ServerDelegateV2, RequestHandler, WebConnectionSubject, WebConnectionListSubject, WebConnectionRequestSubject, WebConnectionSingleRequestSubject, ClientDelegateV2 {

    static let shared = WebConnectionController()

    private var server: Server!
    private let connectionRepository = WebConnectionRepository()
    private let sessionTransformer = WebConnectionToSessionTransformer()

    private var client: Client!

    private static let safeWebConnectionLoadingTimeout: TimeInterval = 30
    private static let walletConnectionLoadingTimeout: TimeInterval = 180

    init() {
        server = WalletConnectSwift.Server(delegate: self)
        server.register(handler: self)
        client = WalletConnectSwift.Client(delegate: self)
    }

    deinit {
        server.unregister(handler: self)
    }

    // MARK: - Connection Observers

    private var connectionObservers: [WebConnectionURL: [WebConnectionObserver]] = [:]

    func attach(observer: WebConnectionObserver, to connection: WebConnection) {
        if var existing = connectionObservers[connection.connectionURL] {
            guard !existing.contains(where: { $0 === observer  }) else { return }
            existing.append(observer)
            connectionObservers[connection.connectionURL] = existing
        } else {
            connectionObservers[connection.connectionURL] = [observer]
        }
    }

    func detach(observer: WebConnectionObserver) {
        for key in connectionObservers.keys {
            if var existing = connectionObservers[key], let index = existing.firstIndex(where: { $0 === observer }) {
                existing.remove(at: index)
                connectionObservers[key] = existing
            }
        }
    }

    func notifyObservers(of connection: WebConnection) {
        guard let toNotify = connectionObservers[connection.connectionURL], let connection = self.connection(for: connection.connectionURL) else { return }
        for observer in toNotify {
            observer.didUpdate(connection: connection)
        }
    }

    // MARK: - Connection List Observers

    private var listObservers: [WebConnectionListObserver] = []

    func attach(observer: WebConnectionListObserver) {
        guard !listObservers.contains(where: { $0 === observer }) else { return }
        listObservers.append(observer)
    }

    func detach(observer: WebConnectionListObserver) {
        if let index = listObservers.firstIndex(where: { $0 === observer }) {
            listObservers.remove(at: index)
        }
    }

    func notifyListObservers() {
        for observer in listObservers {
            observer.didUpdateConnections()
        }
    }

    // MARK: - Request Observer

    private var requestListObservers: [WebConnectionRequestObserver] = []
    private var requestObservers: [WebRequestIdentifier: [WebConnectionRequestObserver]] = [:]

    func attach(observer: WebConnectionRequestObserver) {
        guard !requestListObservers.contains(where: { $0 === observer }) else { return }
        requestListObservers.append(observer)
    }

    func attach(observer: WebConnectionRequestObserver, to request: WebConnectionRequest) {
        guard let url = request.connectionURL, let id = request.id else { return }
        var requestListObservers = requestObservers[WebRequestIdentifier(url, id)] ?? []
        guard !requestListObservers.contains(where: { $0 === observer }) else { return }
        requestListObservers.append(observer)
        requestObservers[WebRequestIdentifier(url, id)] = requestListObservers
    }

    func detach(observer: WebConnectionRequestObserver) {
        if let index = requestListObservers.firstIndex(where: { $0 === observer }) {
            requestListObservers.remove(at: index)
        }
        for key in requestObservers.keys {
            var list = requestObservers[key]!
            if let index = list.firstIndex(where: { $0 === observer }) {
                list.remove(at: index)
                requestObservers[key] = list
            }
        }
    }

    func notifyObservers(of request: WebConnectionRequest) {
        for observer in requestListObservers {
            observer.didUpdate(request: request)
        }

        if let url = request.connectionURL, let id = request.id, let list = requestObservers[WebRequestIdentifier(url, id)] {
            for observer in list {
                observer.didUpdate(request: request)
            }
        }
    }

    /// Returns list of keys that can be used as wallets for this connection.
    ///
    /// - Returns: all keys that can be connected.
    func accountKeys() -> [KeyInfo] {
        do {
            let result = try KeyInfo.all()
            return result
        } catch {
            return []
        }
    }

    // MARK: - Connecting

    func connect(to string: String) throws -> WebConnection {
        var remotePeerType: WebConnectionPeerType = .dapp
        // create connection from the url string
        var string = string
        if string.hasPrefix("safe-wc:") {
            string.removeFirst("safe-".count)
            remotePeerType = .gnosisSafeWeb
        }
        // for now only handle 'safe web' to 'wallet' connections
        guard remotePeerType == .gnosisSafeWeb, let url = WebConnectionURL(string: string) else {
            throw WebConnectionError.urlNotSupported
        }
        if let connection = connection(for: url) {
            // if already exists, resume from the current status
            update(connection, to: connection.status)
            return connection
        } else {
            let connection = createConnection(from: url)
            update(connection, to: .handshaking)
            return connection
        }
    }

    /// Implements the state machine transitions of a connection. Persists the connection.
    ///
    /// - Parameters:
    ///   - connection: a connection to transition to another state
    ///   - newStatus: new state.
    private func update(_ connection: WebConnection, to newStatus: WebConnectionStatus) {
        connection.status = newStatus
        save(connection)

        switch newStatus {
        case .initial:
            // do nothing
            break

        case .handshaking:
            do {
                try start(connection)
            } catch {
                handle(error: error, in: connection)
            }

        case .approving:
            // wait for user response, do nothing
            break

        case .approved:
            respondToSessionCreation(connection)
            update(connection, to: .opened)

        case .rejected:
            respondToSessionCreation(connection)
            update(connection, to: .final)

        case .opened:
            updateActivityDate(connection: connection)
            notifyListObservers()

        case .closed:
            disconnect(connection)
            update(connection, to: .final)

        case .final:
            notifyObservers(of: connection)
            deleteOutstandingRequests(connection)
            delete(connection)
            notifyListObservers()

        case .unknown:
            // stay here
            break
        }

        if connection.status == newStatus {
            notifyObservers(of: connection)
        }
    }

    private func start(_ connection: WebConnection) throws {
        do {
            guard let local = connection.localPeer else {
                assertionFailure("Misconfigured connection: local peer is missing")
                throw WebConnectionError.configurationError
            }
            switch local.role {
            case .wallet:
                try server.connect(to: connection.connectionURL.wcURL)
                scheduleTimeout(connectionURL: connection.connectionURL, timeout: Self.safeWebConnectionLoadingTimeout)

            case .dapp:
                try client.connect(to: connection.connectionURL.wcURL)
                scheduleTimeout(connectionURL: connection.connectionURL, timeout: Self.walletConnectionLoadingTimeout)

            default:
                throw WebConnectionError.unsupportedConnectionType
            }
        } catch {
            throw WebConnectionError.connectionFailure(error)
        }
    }

    // if connection still waiting to receive 'connection request' from the other side after
    // timeout, then we close it with error.
    private func scheduleTimeout(connectionURL: WebConnectionURL, timeout: TimeInterval) {
        Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if let connection = self.connection(for: connectionURL), connection.status == .handshaking {
                self.handle(error: WebConnectionError.connectionStartTimeout, in: connection)
            }
        }
    }

    private func updateActivityDate(connection: WebConnection) {
        connection.lastActivityDate = Date()
        let secondsIn24Hours: TimeInterval = 24 * 60 * 60
        connection.expirationDate = connection.lastActivityDate!.addingTimeInterval(secondsIn24Hours)
        save(connection)
    }

    private func handle(error: Error, in connection: WebConnection) {
        connection.lastError = error.localizedDescription
        update(connection, to: .final)
    }

    private func respondToSessionCreation(_ connection: WebConnection) {
        // only applicable for wallet role
        guard let peer = connection.localPeer, peer.role == .wallet else {
            return
        }

        guard
            let session = sessionTransformer.session(from: connection),
            let request = pendingConnectionRequest(connection: connection),
            let requestId = request.id.flatMap(sessionTransformer.requestId(id:)),
            let walletInfo = session.walletInfo
        else {
            update(connection, to: .closed)
            return
        }
        server.sendCreateSessionResponse(for: requestId, session: session, walletInfo: walletInfo)
        delete(request)
    }

    func reconnect() {
        let connections = connectionRepository.connections(status: WebConnectionStatus.opened)
        let sessions = connections.map(sessionTransformer.session(from:))

        for (session, connection) in zip(sessions, connections) where session != nil {
            do {
                if connection.localPeer?.role == .wallet {
                    try server.reconnect(to: session!)
                } else if connection.localPeer?.role == .dapp {
                    try client.reconnect(to: session!)
                }
            } catch {
                handle(error: userError(from: error), in: connection)
            }
        }

        let allPendingRequests: [WebConnectionRequest] = pendingRequests()
        for request in allPendingRequests {
            notifyObservers(of: request)
        }

        // clear the pending wallet connections because we lost the context of adding a key
        let pendingWalletConnections = connectionRepository.connections(status: .handshaking).filter { $0.localPeer?.role == .dapp }
        for connection in pendingWalletConnections {
            update(connection, to: .closed)
        }
    }

    func handleExpiredConnections() {
        let now = Date()
        let connections = connectionRepository.connections(expiredAt: now)
        for connection in connections {
            expire(connection)
        }
    }

    // MARK: - Managing WebConnection

    func connections() -> [WebConnection] {
        connectionRepository.connections().filter { connection in
            connection.localPeer?.role == .wallet &&
            connection.remotePeer?.peerType == .gnosisSafeWeb &&
            connection.remotePeer?.role == .dapp
        }
    }

    func connection(for session: Session) -> WebConnection? {
        connection(for: session.url)
    }

    func connection(for url: WCURL) -> WebConnection? {
        connection(for: WebConnectionURL(wcURL: url))
    }

    func connection(for url: WebConnectionURL) -> WebConnection? {
        connectionRepository.connection(url: url)
    }

    func connection(for request: WebConnectionRequest) -> WebConnection? {
        request.connectionURL.flatMap(connection(for:))
    }

    func chain(for request: WebConnectionRequest) -> Chain? {
        connection(for: request).flatMap { $0.chainId }.map(String.init).flatMap { Chain.by($0) }
    }

    func pendingConnectionRequest(connection: WebConnection) -> WebConnectionOpenRequest? {
        connectionRepository.pendingConnectionRequest(url: connection.connectionURL)
    }

    func pendingRequests() -> [WebConnectionRequest] {
        connectionRepository.pendingRequests()
    }

    /// Creates new wallet to gnosis safe web app connection. The dapp information is set to placeholder data except
    /// for the `peerType` and `role`.
    ///
    /// - Parameter url: the URL to connect to
    /// - Returns: new WebConnection with populated url, local peer, remote peer, and the created date set to the current time.
    func createConnection(from url: WebConnectionURL) -> WebConnection {
        // create the new connection with the information about this app and expectation about the dapp to be
        // a gnosis safe web app.
        let connection = WebConnection(connectionURL: url)
        connection.createdDate = Date()
        connection.localPeer = WebConnectionPeerInfo(
                peerId: UUID().uuidString,
                peerType: .thisApp,
                role: .wallet,
                url: App.configuration.services.webAppURL,
                name: "Gnosis Safe",
                description: "The most trusted platform to manage digital assets",
                icons: [App.configuration.services.webAppURL.appendingPathComponent("favicon.ico")],
                deeplinkScheme: "gnosissafe:"
        )
        connection.remotePeer = GnosisSafeWebPeerInfo(
                peerId: "",
                peerType: .gnosisSafeWeb,
                role: .dapp,
                url: App.configuration.services.webAppURL,
                name: "",
                description: nil,
                icons: [],
                deeplinkScheme: nil)
        return connection
    }

    /// Saves the connection to the persistence store
    ///
    /// - Parameter connection: connection to save
    func save(_ connection: WebConnection) {
        connectionRepository.save(connection)
    }

    /// Deletes the connection from the persistence store
    ///
    /// - Parameter connection: connection to delete
    func delete(_ connection: WebConnection) {
        connectionRepository.delete(connection)
    }

    func delete(_ request: WebConnectionRequest) {
        connectionRepository.delete(request: request)
    }

    /// Disconnects the connection from gnosis safe web app
    ///
    /// - Parameter connection: connection to disconnect
    func disconnect(_ connection: WebConnection) {
        if let session = sessionTransformer.session(from: connection) {
            do {
                guard let peer = connection.localPeer else { return }
                switch peer.role {
                case .wallet:
                    try server.disconnect(from: session)

                case .dapp:
                    try client.disconnect(from: session)

                default:
                    break
                }
            } catch {
                LogService.shared.error("Failed to disconnect: \(error)")
            }
        }
    }

    func expire(_ connection: WebConnection) {
        update(connection, to: .closed)
    }

    func deleteOutstandingRequests(_ connection: WebConnection) {
        let requests = connectionRepository.pendingRequests(connection: connection)
        for request in requests {
            request.status = .failed
            save(request)
            notifyObservers(of: request)
            delete(request)
        }
    }

    // MARK: - User events

    /// Expected to be called by the UI when user approves connection
    ///
    /// - Parameter connection: a connection
    func userDidApprove(_ connection: WebConnection) {
        update(connection, to: .approved)
    }

    /// Expected to be called by UI when user rejects connection
    ///
    /// - Parameter connection: a connection
    func userDidReject(_ connection: WebConnection) {
        update(connection, to: .rejected)
    }

    /// Expected to be called by UI when user cancels connection
    ///
    /// - Parameter connection: a connection
    func userDidCancel(_ connection: WebConnection) {
        update(connection, to: .rejected)
    }

    func userDidDisconnect(_ connection: WebConnection) {
        update(connection, to: .closed)
    }

    func userDidDelete(account: Address) {
        disconnectConnections(account: account)
    }

    func disconnectConnections(account: Address) {
        let connections = connectionRepository.connections(account: account)
        for connection in connections {
            update(connection, to: .closed)
        }
    }

    func userDidChange(network: Chain, in connection: WebConnection) {
        guard let stringId = network.id, let chainId = Int(stringId), connection.chainId != chainId else { return }
        connection.chainId = chainId
        updateSession(from: connection)
    }

    func userDidChange(account: KeyInfo, in connection: WebConnection) {
        guard !connection.accounts.contains(account.address) else { return }
        connection.accounts = [account.address]
        updateSession(from: connection)
    }

    private func updateSession(from connection: WebConnection) {
        guard
            let session = sessionTransformer.session(from: connection),
            let walletInfo = session.walletInfo
        else {
            return
        }

        do {
            if connection.connectedAsWallet {
                try server.updateSession(session, with: walletInfo)
            } else {
                let request = try Request(url: connection.connectionURL.wcURL, method: "wc_sessionUpdate", params: [walletInfo], id: nil)
                try client.send(request, completion: nil)
            }

            update(connection, to: .opened)
        } catch {
            LogService.shared.error("Error updating session: \(error)")
        }
    }

    // MARK: - Server Delegate (Server events)

    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> ()) {
        // ignore this, because we implement another method - didReceiveConnectionRequest
    }

    func server(_ server: Server, didReceiveConnectionRequest requestId: RequestID, for session: Session) {
        // we save the information from the request and wait until user responds with some action.
        // main thread needed because of the CoreData dependency
        DispatchQueue.main.async { [unowned self] in
            guard let connection = connection(for: session) else {
                return
            }
            assert(connection.status == .handshaking)
            sessionTransformer.update(connection: connection, with: session)

            let wcRequest = Request(url: session.url, method: "wc_sessionRequest", id: requestId)
            guard let request = sessionTransformer.request(from: wcRequest) else {
                respondToSessionCreation(connection)
                handle(error: WebConnectionError.connectionStartFailed, in: connection)
                return
            }
            request.status = .pending
            save(request)

            // check that the chain id exists in the app
            if let chainId = connection.chainId, let exists = (try? Chain.exists("\(chainId)")), !exists {
                // respond with rejection and exit with error
                respondToSessionCreation(connection)
                handle(error: WebConnectionError.unsupportedNetwork, in: connection)
            } else {
                update(connection, to: .approving)
            }
        }
    }

    fileprivate func handleConnectionFailure(_ url: WCURL) {
        // the connection process failed
        DispatchQueue.main.async { [unowned self] in
            guard let connection = connection(for: url) else {
                return
            }
            let error = WebConnectionError.connectionStartFailed
            handle(error: error, in: connection)
        }
    }

    func server(_ server: Server, didFailToConnect url: WCURL) {
        handleConnectionFailure(url)
    }

    func server(_ server: Server, didConnect session: Session) {
        // ignore
    }

    fileprivate func handleConnectionClosed(_ session: Session) {
        // when the connection is closed from outside
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let connection = self.connection(for: session) else { return }
            self.update(connection, to: .final)
        }
    }

    func server(_ server: Server, didDisconnect session: Session) {
        handleConnectionClosed(session)
    }

    // this will be called when session's chain Id or accounts change
    // when session is closed (approved = false), the 'disconnect' method will be called instead.
    fileprivate func handleSessionUpdate(_ updatedSession: Session) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let connection = self.connection(for: updatedSession), connection.status == .opened else { return }

            guard let walletInfo = updatedSession.walletInfo else {
                self.update(connection, to: .closed)
                return
            }

            // check that we support chain id
            do {
                let chainExists = try Chain.exists(String(walletInfo.chainId))

                if !chainExists {
                    self.update(connection, to: .closed)
                    return
                } else {
                    connection.chainId = walletInfo.chainId
                }
            } catch {
                LogService.shared.error("Error checking whether chain exists: \(error)")
            }

            if connection.localPeer?.role == .wallet {
                // check that we have the key
                guard let address = walletInfo.accounts.first, let account = Address(address) else {
                    self.update(connection, to: .closed)
                    return
                }

                do {
                    let key = try KeyInfo.firstKey(address: account)

                    if key == nil {
                        self.update(connection, to: .closed)
                        return
                    } else {
                        connection.accounts = [account]
                    }
                } catch {
                    LogService.shared.error("Error checking whether key exists: \(error)")
                }
            } else if connection.localPeer?.role == .dapp {
                // we don't support changing accounts because we keep the addresses static in the owner key list.
                // i.e. if we do, then we would need to allow potentially duplicate owner keys and modify the
                // existing key info on such account change.
                // another alternative would be to allow changing the account as long as it doesn't duplicate another
                // owner key.

                let changedAccounts = walletInfo.accounts.compactMap(Address.init)
                let existingAccounts = connection.accounts

                if Set(changedAccounts) != Set(existingAccounts) {
                    connection.lastError = WebConnectionError.unexpectedAccount.localizedDescription
                    self.update(connection, to: .closed)
                    return
                }
            }

            // all checks passed, update the connection.
            self.update(connection, to: .opened)
        }
    }

    func server(_ server: Server, didUpdate updatedSession: Session) {
        handleSessionUpdate(updatedSession)
    }

    func server(_ server: Server, willReconnect session: Session) {
        // not implemented
    }

    // MARK: - Server Request Handling

    func canHandle(request: Request) -> Bool {
        ["eth_sign", "eth_sendTransaction"].contains(request.method)
    }

    func handle(request wcRequest: Request) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in self?.handle(request: wcRequest) }
            return
        }
        // convert WC request to a connection request
        guard let request = sessionTransformer.request(from: wcRequest) else {
            try? server.send(Response(request: wcRequest, error: .invalidParams))
            return
        }
        guard let url = request.connectionURL, let connection = connection(for: url), connection.status == .opened else {
            try? server.send(Response(request: wcRequest, error: .internalError))
            return
        }

        switch request {
        case let signRequest as WebConnectionSignatureRequest:
            guard connection.accounts.contains(signRequest.account) else {
                try? server.send(Response(request: wcRequest, error: .invalidParams))
                return
            }

        case let sendTxRequest as WebConnectionSendTransactionRequest:
            guard let from = sendTxRequest.transaction.from,
                  connection.accounts.contains(Address(from))
            else {
                try? server.send(Response(request: wcRequest, error: .invalidParams))
                return
            }
            let address = Address(from)

            // reject ledger nano x because it is not yet supported for sending transactions
            if let key = try? KeyInfo.firstKey(address: address), key.keyType == .ledgerNanoX {
                try? server.send(Response(request: wcRequest, error: .requestRejected))
                App.shared.snackbar.show(message: "Executing transactions with Ledger Nano X is not supported.")
                return
            }
            prepareTransactionForExecution(sendTxRequest)

        default:
            break
        }
        updateActivityDate(connection: connection)
        request.status = .pending
        request.createdDate = Date()
        save(request)
        notifyObservers(of: request)
    }

    func prepareTransactionForExecution(_ request: WebConnectionSendTransactionRequest) {
        guard
            let connection = connection(for: request),
            let chainId = connection.chainId,
            let chain = chain(for: request),
            let features = chain.features
        else {
            return
        }

        let minerTip: Sol.UInt256 = 1_500_000_000

        // select tx type based on the chain.
        let isEIP1559 = features.contains("EIP1559")
        if isEIP1559 {
            request.transaction = Eth.TransactionEip1559(
                chainId: Sol.UInt256(chainId),
                from: request.transaction.from,
                to: request.transaction.to,
                value: request.transaction.value,
                data: request.transaction.data,
                fee: .init(maxPriorityFee: minerTip)
            )
        } else {
            request.transaction = Eth.TransactionLegacy(
                chainId: Sol.UInt256(chainId),
                from: request.transaction.from,
                to: request.transaction.to,
                value: request.transaction.value,
                data: request.transaction.data
            )
        }
    }

    func request(_ connectionURL: WebConnectionURL, _ requestId: WebConnectionRequestId) -> WebConnectionRequest? {
        connectionRepository.request(connectionURL: connectionURL, requestId: requestId)
    }

    func respond<T>(request: WebConnectionRequest, with value: T) where T: Codable {
        guard
            let connectionURL = request.connectionURL,
            let requestId = request.id,
            let id = sessionTransformer.requestId(id: requestId),
            let request = self.request(connectionURL, requestId),
            request.status == .pending
        else { return }

        if let connection = connection(for: connectionURL), connection.status == .opened {
            do {
                try server.send(Response(url: connectionURL.wcURL, value: value, id: id))
            } catch {
                LogService.shared.error("Failed to respond to WC server: \(error)")
            }
        }
        request.status = .success
        notifyObservers(of: request)
        delete(request)
    }

    func respond(request: WebConnectionRequest, errorCode: Int, message: String) {
        guard
            let connectionURL = request.connectionURL,
            let requestId = request.id,
            let id = sessionTransformer.requestId(id: requestId),
            let request = self.request(connectionURL, requestId),
            request.status == .pending
        else { return }
        if let connection = connection(for: connectionURL), connection.status == .opened {
            do {
                try server.send(Response(url: connectionURL.wcURL, errorCode: errorCode, message: message, id: id))
            } catch {
                LogService.shared.error("Failed to return error to WC server: \(error)")
            }
        }
        request.status = .failed
        notifyObservers(of: request)
        delete(request)
    }

    func save(_ request: WebConnectionRequest) {
        connectionRepository.save(request)
    }

    // MARK: - Client Delegate

    // called when creating connection or creating a session
    func client(_ client: Client, dappInfoForUrl url: WCURL) -> Session.DAppInfo? {
        guard let connection = connection(for: url),
              let session = sessionTransformer.session(from: connection) else {
            return nil
        }
        return session.dAppInfo
    }

    // called when failed to connect to bridge server or to establsih session
    func client(_ client: Client, didFailToConnect url: WCURL) {
        handleConnectionFailure(url)
    }

    // called when successfully connected to a bridge server
    func client(_ client: Client, didConnect url: WCURL) {
        // nothing to do
    }

    // called when successfully established session (handshake success).
    // also called on re-connect to the bridge
    func client(_ client: Client, didConnect session: Session) {
        DispatchQueue.main.async { [unowned self] in
            guard let connection = connection(for: session), connection.status == .handshaking else {
                return
            }
            sessionTransformer.update(connection: connection, with: session)

            // check that the chain id exists in the app
            if let chainId = connection.chainId, let exists = (try? Chain.exists("\(chainId)")), !exists {
                // respond with rejection and close connection
                connection.lastError = WebConnectionError.unsupportedNetwork.localizedDescription
                update(connection, to: .closed)
            } else {
                update(connection, to: .approved)
            }
        }
    }

    // called when received 'wc_updateSession' with approved = false
    func client(_ client: Client, didDisconnect session: Session) {
        handleConnectionClosed(session)
    }

    // called when received 'wc_updateSession' with approved = true
    func client(_ client: Client, didUpdate session: Session) {
        handleSessionUpdate(session)
    }

    func client(_ client: Client, willReconnect session: Session) {
        // not implemented
    }

    // MARK: - Connect Wallet Logic

    func walletConnection(keyInfo: KeyInfo) -> [WebConnection] {
        let result = connectionRepository.connections(account: keyInfo.address).filter { connection in
            connection.localPeer?.role == .dapp && connection.remotePeer?.role == .wallet
        }
        return result
    }

    // create connection to a wallet
    func connect(wallet info: WCAppRegistryEntry?, chainId: Int?) throws -> WebConnection {
        let handshakeTopic = UUID().uuidString
        let bridgeURL = App.configuration.walletConnect.bridgeURL
        guard let encryptionKey = Data(randomOfSize: 32) else {
            throw WebConnectionError.keyGenerationFailed
        }
        let wcURL = WCURL(topic: handshakeTopic, version: "1", bridgeURL: bridgeURL, key: encryptionKey.toHexStringWithPrefix())
        let connection = createWalletConnection(from: WebConnectionURL(wcURL: wcURL), info: info)
        connection.chainId = chainId
        update(connection, to: .handshaking)
        return connection
    }

    func createWalletConnection(from url: WebConnectionURL, info: WCAppRegistryEntry?) -> WebConnection {
        let connection = WebConnection(connectionURL: url)
        connection.createdDate = Date()
        connection.localPeer = WebConnectionPeerInfo(
                peerId: UUID().uuidString,
                peerType: .thisApp,
                role: .dapp,
                url: App.configuration.services.webAppURL,
                name: "Gnosis Safe",
                description: "The most trusted platform to manage digital assets",
                icons: [App.configuration.services.webAppURL.appendingPathComponent("favicon.ico")],
                deeplinkScheme: "gnosissafe:"
        )
        if let info = info {
            connection.remotePeer = WebConnectionPeerInfo(
                peerId: "",
                peerType: .wallet,
                role: .wallet,
                url: info.homepage ?? App.configuration.services.webAppURL,
                name: info.name,
                description: info.description,
                icons: info.imageLargeUrl.map { [$0] } ?? [],
                deeplinkScheme: info.linkMobileNative?.absoluteString)
        } else {
            connection.remotePeer = WebConnectionPeerInfo(
                peerId: "",
                peerType: .wallet,
                role: .wallet,
                url: App.configuration.services.webAppURL,
                name: "WalletConnect",
                description: "WalletConnect",
                icons: [],
                deeplinkScheme: "wc:")
        }
        return connection
    }

    // MARK: - Sending Requests to Wallet

    func sendTransaction(connection: WebConnection, transaction: Client.Transaction, completion: @escaping (Result<Data, Error>) -> ()) {
        do {
            try client.eth_sendTransaction(url: connection.connectionURL.wcURL, transaction: transaction) { response in
                DispatchQueue.main.async {
                    if let error = response.error {
                        completion(.failure(error))
                    } else if let data = try? response.result(as: DataString.self) {
                        completion(.success(data.data))
                    }
                }
            }
        } catch {
            completion(.failure(userError(from: error)))
        }
    }

    private func userError(from error: Error) -> Error {
        switch error {
        case WalletConnectSwift.Client.ClientError.missingWalletInfoInSession,
            WalletConnectSwift.Client.ClientError.sessionNotFound,
            WalletConnectSwift.Server.ServerError.missingWalletInfoInSession:
            return WebConnectionError.connectionLost
        case WalletConnectSwift.Server.ServerError.failedToCreateSessionResponse:
            return WebConnectionError.connectionStartFailed
        default:
            return error
        }
    }
    
    // MARK: - Signing
    
    func wcSign(connection: WebConnection, message: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard
            let session = sessionTransformer.session(from: connection),
            let walletAddress = session.walletInfo?.accounts.first else {
                completion(.failure(GSError.WalletNotConnected(description: "Could not sign message")))
                return
            }
        
        do {
            try client.eth_sign(url: session.url, account: walletAddress, message: message) { [weak self] in
                self?.handleSignResponse($0, completion: completion)
            }
        } catch {
            completion(.failure(userError(from: error)))
        }
    }
    
    func wcSign(connection: WebConnection, transaction: Transaction, completion: @escaping (Result<String, Error>) -> Void) {
        guard
            let session = sessionTransformer.session(from: connection),
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
                    self?.handleSignResponse($0, completion: completion)
                }
            default:
                let message = transaction.safeTxHash.description
                try client.eth_sign(url: session.url, account: walletAddress, message: message) { [weak self] response in
                    DispatchQueue.main.async {
                        self?.handleSignResponse(response, completion: completion)
                    }
                }
            }
        } catch {
            completion(.failure(userError(from: error)))
        }
    }
    
    private func handleSignResponse(_ response: Response, completion: @escaping (Result<String, Error>) -> Void) {
        if let error = response.error {
            completion(.failure(error))
            return
        }
        do {
            var signature = try response.result(as: String.self)

            var signatureBytes = Data(hex: signature).bytes

            if signatureBytes.count == 65 {
                var v = signatureBytes.last!
                if v < 27 {
                    v += 27
                    signatureBytes[signatureBytes.count - 1] = v
                    signature = Data(signatureBytes).toHexStringWithPrefix()
                }

                completion(.success(signature))
            } else {
                completion(.success(signature))
            }
        } catch {
            completion(.failure(error))
        }
    }
}

/// User-visible error
struct WebConnectionError: CustomNSError {
    private(set) static var errorDomain: String = "io.gnosis.safe.WebConnection"
    var errorCode: Int
    var message: String
    var cause: Error? = nil
    var errorUserInfo: [String: Any] {
        var result: [String: Any] = [NSLocalizedDescriptionKey: message]
        if let error = cause {
            result[NSUnderlyingErrorKey] = error
        }
        return result
    }
}

extension WebConnectionError {
    /// When the connection URL is not of expected type
    static let urlNotSupported = WebConnectionError(errorCode: -1, message: "This URL type is not supported.")

    /// When the connection failed to establish
    ///
    /// - Parameter error: underlying error
    /// - Returns: an error value
    static func connectionFailure(_ error: Error) -> WebConnectionError {
        WebConnectionError(errorCode: -2, message: "Failed to connect.", cause: error)
    }

    /// When the connection failed to start and can be retried.
    static let connectionStartFailed = WebConnectionError(errorCode: -3, message: "Failed to start connection. Please try again.")

    static let unsupportedNetwork = WebConnectionError(errorCode: -4, message: "Failed to connect. Requested network is not supported.")

    static let connectionStartTimeout = WebConnectionError(errorCode: -5, message: "Connection timeout. Please reload web app.")

    static let keyGenerationFailed = WebConnectionError(errorCode: -6, message: "Failed to create encryption key. Please try again.")

    static let configurationError = WebConnectionError(errorCode: -7, message: "Configuration error. Please try again.")

    static let unsupportedConnectionType = WebConnectionError(errorCode: -8, message: "Unsupported connection type. Please try again.")

    static let unexpectedAccount = WebConnectionError(errorCode: -9, message: "Unexpected account change. Please connect new account instead of changing existing one.")

    static let connectionLost = WebConnectionError(errorCode: -10, message: "Connection lost. Please reconnect and try again.")
}

