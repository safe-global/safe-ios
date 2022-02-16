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

/// Controller implementing the business-logic of managing connections and handling incoming requests.
///
/// Use the `shared` instance since the controller's lifetime is the same as the app's lifetime.
///
/// Remember to set the `delegate` in order to respond to connection events.
class WebConnectionController: ServerDelegateV2, RequestHandler, WebConnectionSubject {

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

    private var observers: [WebConnectionURL: [WebConnectionObserver]] = [:]

    func attach(observer: WebConnectionObserver, to connection: WebConnection) {
        if var existing = observers[connection.connectionURL] {
            existing.append(observer)
            observers[connection.connectionURL] = existing
        } else {
            observers[connection.connectionURL] = [observer]
        }
    }

    func detach(observer: WebConnectionObserver) {
        for key in observers.keys {
            if var existing = observers[key], let index = existing.firstIndex(where: { $0 === observer }) {
                existing.remove(at: index)
                observers[key] = existing
            }
        }
    }

    func notifyObservers(of connection: WebConnection) {
        guard let toNotify = observers[connection.connectionURL] else { return }
        for observer in toNotify {
            observer.didUpdate(connection: connection)
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
            didOpen(connection: connection)

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
            // wait for result
            // when got it, send update
            // move to update sent
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
            delete(connection)
            break
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

    private func didOpen(connection: WebConnection) {
        connection.lastActivityDate = Date()
        let secondsIn24Hours: TimeInterval = 24 * 60 * 60
        connection.expirationDate = connection.createdDate!.addingTimeInterval(secondsIn24Hours)
        save(connection)
    }

    private func handle(error: Error, in connection: WebConnection) {
        connection.lastError = error.localizedDescription
        update(connection, to: .final)
    }

    private func respondToSessionCreation(_ connection: WebConnection) {
        guard
            let session = sessionTransformer.session(from: connection),
            let request = connection.pendingRequest,
            let requestId = sessionTransformer.requestId(from: request),
            let walletInfo = session.walletInfo
        else {
            assertionFailure("Expected to have a valid connection")
            return
        }
        server.sendCreateSessionResponse(for: requestId, session: session, walletInfo: walletInfo)
        connection.pendingRequest = nil
    }

    // MARK: - Managing WebConnection

    func connection(for session: Session) -> WebConnection? {
        connection(for: session.url)
    }

    func connection(for url: WCURL) -> WebConnection? {
        connection(for: WebConnectionURL(wcURL: url))
    }

    func connection(for url: WebConnectionURL) -> WebConnection? {
        connectionRepository.connection(url: url)
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
            connection.pendingRequest = sessionTransformer.request(id: requestId)

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
            guard let connection = connection(for: url) else { return }
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
    }

    func server(_ server: Server, didUpdate session: Session) {
        // update recieved
        print("updated")
    }

    // MARK: - Server Request Handling

    func canHandle(request: Request) -> Bool {
        false
    }

    func handle(request: Request) {
    }

    // MARK: - Signing

    // received signature request

    // ask user about signature request

    // confirm signature request

    // reject signature request

    // cancel signature request


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
            result[NSUnderlyingErrorKey]  = error
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
