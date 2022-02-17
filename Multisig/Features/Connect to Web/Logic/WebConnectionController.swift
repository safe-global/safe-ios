//
// Created by Dmitry Bespalov on 10.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

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

/// Controller implementing the business-logic of managing connections and handling incoming requests.
///
/// Use the `shared` instance since the controller's lifetime is the same as the app's lifetime.
///
/// Remember to set the `delegate` in order to respond to connection events.
class WebConnectionController: ServerDelegateV2, RequestHandler, WebConnectionSubject, WebConnectionListSubject, WebConnectionRequestSubject {

    static let shared = WebConnectionController()

    private var server: Server!
    private let connectionRepository = WebConnectionRepository()
    private let sessionTransformer = WebConnectionToSessionTransformer()

    init() {
        server = WalletConnectSwift.Server(delegate: self)
        server.register(handler: self)
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
        guard let toNotify = connectionObservers[connection.connectionURL] else { return }
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

    private var requestObservers: [WebConnectionRequestObserver] = []

    func attach(observer: WebConnectionRequestObserver) {
        guard !requestObservers.contains(where: { $0 === observer }) else { return }
        requestObservers.append(observer)
    }

    func detach(observer: WebConnectionRequestObserver) {
        if let index = requestObservers.firstIndex(where: { $0 === observer }) {
            requestObservers.remove(at: index)
        }
    }

    func notifyObservers(of request: WebConnectionRequest) {
        for observer in requestObservers {
            observer.didUpdate(request: request)
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
        defer {
            notifyObservers(of: connection)
        }

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

        case .updateReceived:
            // close connection
            // or change network
            // or reject update / ignore it
            break

        case .updateSent:
            // if was not approved, close connection
            // else move back to opened
            break
        case .changingNetwork:
            // wait for the result
            // when got result, send update
            // move to update sent
            break
        case .changingAccount:
            // wait for the result
            // when got it, send update
            // move to update sent
            break
        case .disconnecting:
            disconnect(connection)
            update(connection, to: .final)
            break
        case .expired:
            // stay here.
            break
        case .requestReceived:
            // save the request completion
            // ask user to process
            // move to processing
            break
        case .requestProcessing:
            // wait for result
            // when got it, handle it.
            // move to response sent
            // remove completion
            break
        case .responseSent:
            // go back to opened
            break
        case .closed:
            // go to final
            break
        case .final:
            didFinal(connection: connection)
        case .unknown:
            // stay here
            break
        }
    }

    private func start(_ connection: WebConnection) throws {
        do {
            try server.connect(to: connection.connectionURL.wcURL)
        } catch {
            throw WebConnectionError.connectionFailure(error)
        }
    }

    private func updateActivityDate(connection: WebConnection) {
        connection.lastActivityDate = Date()
        let secondsIn24Hours: TimeInterval = 24 * 60 * 60
        connection.expirationDate = connection.createdDate!.addingTimeInterval(secondsIn24Hours)
        save(connection)
    }

    private func didFinal(connection: WebConnection) {
        delete(connection)
        notifyListObservers()
    }

    private func handle(error: Error, in connection: WebConnection) {
        connection.lastError = error.localizedDescription
        update(connection, to: .final)
    }

    private func respondToSessionCreation(_ connection: WebConnection) {
        guard
            let session = sessionTransformer.session(from: connection),
            let request = pendingConnectionRequest(connection: connection),
            let requestId = request.id.flatMap(sessionTransformer.requestId(id:)),
            let walletInfo = session.walletInfo
        else {
            assertionFailure("Expected to have a valid connection")
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
                try server.reconnect(to: session!)
            } catch {
                handle(error: error, in: connection)
            }
        }

        let allPendingRequests: [WebConnectionRequest] = pendingRequests()
        for request in allPendingRequests {
            notifyObservers(of: request)
        }
    }

    // MARK: - Managing WebConnection

    func connections() -> [WebConnection] {
        connectionRepository.connections()
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
                url: URL(string: "https://gnosis-safe.io/")!,
                name: "Gnosis Safe",
                description: "The most trusted platform to manage digital assets",
                icons: [URL(string: "https://gnosis-safe.io/app/favicon.ico")!],
                deeplinkScheme: "gnosissafe:"
        )
        connection.remotePeer = GnosisSafeWebPeerInfo(
                peerId: "",
                peerType: .gnosisSafeWeb,
                role: .dapp,
                url: URL(string: "https://gnosis-safe.io/")!,
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
                try server.disconnect(from: session)
            } catch {
                // do nothing
            }
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

    func userDidDelete(_ connection: WebConnection) {
        update(connection, to: .final)
    }

    func userDidDisconnect(_ connection: WebConnection) {
        update(connection, to: .disconnecting)
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

    func server(_ server: Server, didFailToConnect url: WCURL) {
        // the connection process failed
        DispatchQueue.main.async { [unowned self] in
            guard let connection = connection(for: url) else {
                return
            }
            assert(connection.status == .handshaking || connection.status == .approving,
                    "Unexpected connection failure in the status \(connection.status)")
            let error = WebConnectionError.connectionStartFailed
            handle(error: error, in: connection)
        }
    }

    func server(_ server: Server, didConnect session: Session) {
        // when connection to the session is established
        // when re-connection to session is established
        print("connected")
    }

    func server(_ server: Server, didDisconnect session: Session) {
        // when the connection is closed from outside
        print("disconnected")
        if let connection = connectionRepository.connection(url: WebConnectionURL(wcURL: session.url)) {
            didFinal(connection: connection)
        }
    }

    func server(_ server: Server, didUpdate session: Session) {
        // update recieved
        print("updated")
    }

    // MARK: - Server Request Handling

    func canHandle(request: Request) -> Bool {
        ["eth_sign"].contains(request.method)
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

        default:
            break
        }
        updateActivityDate(connection: connection)
        request.status = .pending
        request.createdDate = Date()
        save(request)
        notifyObservers(of: request)
    }

    func request(_ connectionURL: WebConnectionURL, _ requestId: WebConnectionRequestId) -> WebConnectionRequest? {
        connectionRepository.request(connectionURL: connectionURL, requestId: requestId)
    }

    func respond<T>(request: WebConnectionRequest, with value: T) where T: Codable {
        guard
            let connectionURL = request.connectionURL,
            let requestId = request.id,
            let connection = connection(for: connectionURL),
            connection.status == .opened,
            let id = sessionTransformer.requestId(id: requestId),
            let request = self.request(connectionURL, requestId),
            request.status == .pending
        else { return }
        request.status = .success
        save(request)
        do {
            try server.send(Response(url: connectionURL.wcURL, value: value, id: id))
        } catch {
            LogService.shared.error("Failed to respond to WC server: \(error)")
        }
        delete(request)
    }

    func respond(request: WebConnectionRequest, errorCode: Int, message: String) {
        guard
            let connectionURL = request.connectionURL,
            let requestId = request.id,
            let connection = connection(for: connectionURL),
            connection.status == .opened,
            let id = sessionTransformer.requestId(id: requestId),
            let request = self.request(connectionURL, requestId),
            request.status == .pending
        else { return }
        request.status = .failed
        save(request)
        do {
            try server.send(Response(url: connectionURL.wcURL, errorCode: errorCode, message: message, id: id))
        } catch {
            LogService.shared.error("Failed to return error to WC server: \(error)")
        }
        delete(request)
    }

    func save(_ request: WebConnectionRequest) {
        connectionRepository.save(request)
    }

    // MARK: - Sending Transaction

    // received transaction request

    // ask user about transaction request

    // confirm transaction request

    // reject transaction request

    // cancel transaction request


    // MARK: - Changing Network

    // received change network request

    // [ask user about change network request]

    // confirm change network request

    // reject change network request


    // user asked to change network - show what's possible

    // user changed network

    // confirm change network request


    // MARK: - Changing Account(s)

    // user asked to change account(s) - show what's possible

    // user changed account(s)

    // confirm change account(s) request


    // MARK: - Disconnecting

    // user asked to disconnect

    // confirm disconnect request


    // received disconnect request

    // close the connection


    // received timer event to check for connection session expirations

    // make connection session expired


    // user asked to reconnect expired connection session


    // record last activity on the connection
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
}
