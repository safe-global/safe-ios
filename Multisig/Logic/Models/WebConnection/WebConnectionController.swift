//
// Created by Dmitry Bespalov on 10.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

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
    static let urlNotSupported = WebConnectionError(errorCode: -1, message: "This URL type is not supported.")
    static func connectionFailure(_ error: Error) -> WebConnectionError {
        WebConnectionError(errorCode: -2, message: "Failed to connect.", cause: error)
    }
    static let connectionStartFailed = WebConnectionError(errorCode: -2, message: "Failed to start connection. Please try again.")
    static let canceled = WebConnectionError(errorCode: -3, message: "Canceled by user")
    static let rejected = WebConnectionError(errorCode: -3, message: "Rejected by user")
}

protocol WebConnectionControllerDelegate: AnyObject {
    func respondToConnection(_ connection: WebConnection, completion: @escaping () -> Void)
    func didFail(with error: Error)
}

class WebConnectionController: ServerDelegate, RequestHandler {

    static let shared = WebConnectionController()

    let server: Server
    weak var delegate: WebConnectionControllerDelegate?
    var connectionRequestClosures: [WebConnectionURL: (Session.WalletInfo) -> ()] = [:]

    init() {
        server = WalletConnectSwift.Server(delegate: self)
        server.register(handler: self)
    }

    deinit {
        server.unregister(handler: self)
    }

    /// Returns list of keys that can be used as wallets for this connection.
    ///
    /// - Returns: all keys that can be connected.
    func accountKeys() -> [KeyInfo] {
        do {
            try KeyInfo.all()
        } catch {
            return []
        }
    }

    // create url if it's a valid string
//    func connectionURL(from string: String) -> WebConnectionURL? {
//        guard string.hasPrefix("safe-wc:") else { return nil }
//        WebConnectionURL(string: string)
//    }

    // MARK: - Connecting

    func update(_ connection: WebConnection, to newStatus: WebConnectionStatus) {
        connection.status = newStatus
        save(connection)

        switch newStatus {
        case .initial:
            // do nothing
            break
        case .urlReceived:
            // created connection
            update(connection, to: .handshakeStarted)
        case .handshakeStarted:
            do {
                try start(connection)
            } catch {
                handle(error: error, in: connection)
            }
        case .approving:
            askUserForConnectionRequest(connection)
        case .approved:
            approve(connection)
            update(connection, to: .opened)
        case .rejected:
            reject(connection)
            update(connection, to: .final)
        case .canceled:
            cancel(connection)
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
            // delete connection
            break
        case .unknown:
            // stay here
            break
        }
    }

    private func didOpen(connection: WebConnection) {
        connection.createdDate = Date()
        connection.lastActivityDate = Date()
        let secondsIn24Hours = 24 * 60 * 60
        connection.expirationDate = connection.createdDate!.addingTimeInterval(secondsIn24Hours)
        save(connection)
    }

    private func handle(error: Error, in: WebConnection) {
        delegate?.didFail(with: error)
        update(`in`, to: .final)
    }

    // connect to url
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
        var connection = WebConnection(connectionURL: url)
        // TODO: create local peer, local chain id
        update(connection, to: .urlReceived)
    }

    func start(_ connection: WebConnection) throws {
        do {
            try server.connect(to: connection.connectionURL.wcURL)
        } catch {
            throw WebConnectionError.connectionFailure(error)
        }
    }

    // received connection request
    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> ()) {
        guard let connection = connection(for: session), connection.status == .handshakeStarted else { return }
        update(connection, with: session)
        connectionRequestClosures[connection.connectionURL] = completion
        update(connection, to: .approving)
    }

    func server(_ server: Server, didFailToConnect url: WCURL) {
        guard let connection = connection(for: url), connection.status == .handshakeStarted else { return }
        let error = WebConnectionError.connectionStartFailed
        handle(error: error, in: connection)
    }

    func server(_ server: Server, didConnect session: Session) {
        // when connection to the session is established
        // when re-connection to session is established
    }

    func server(_ server: Server, didDisconnect session: Session) {
        // when the connection is closed from outside
    }

    func server(_ server: Server, didUpdate session: Session) {
        // update recieved
    }

    func askUserForConnectionRequest(_ connection: WebConnection) {
        delegate?.respondToConnection(connection) { [weak self] (result: Result<Void, Error>) in
            guard let self = self else { return }
            do {
                _ = try result.get()
                self.update(connection, to: .approved)
            } catch WebConnectionError.canceled {
                self.update(connection, to: .canceled)
            } catch {
                self.update(connection, to: .rejected)
            }
        }
    }

    func reject(_ connection: WebConnection) {
        guard let closure = connectionRequestClosures[connection.connectionURL] else { return }
        let rejectedResponse = Session.WalletInfo(approved: false, accounts: [], chainId: 0, peerId: "", peerMeta: peerMeta(from: connection.localPeer))
        closure(rejectedResponse)
        connectionRequestClosures.removeValue(forKey: connection.connectionURL)
    }

    func approve(_ connection: WebConnection) {
        guard let closure = connectionRequestClosures[connection.connectionURL] else { return }
        let approvedResponse = Session.WalletInfo(
                approved: true,
                accounts: connection.accounts.map { $0.checksummed },
                chainId: connection.chainId!,
                peerId: connection.localPeer!.peerId,
                peerMeta: peerMeta(from: connection.localPeer)
        )
        closure(approvedResponse)
        connectionRequestClosures.removeValue(forKey: connection.connectionURL)
    }

    func peerMeta(from: WebConnectionPeerInfo) -> Session.ClientMeta {
        fatalError()
    }

    func cancel(_ connection: WebConnection) {
        guard let closure = connectionRequestClosures[connection.connectionURL] else { return }
        connectionRequestClosures.removeValue(forKey: connection.connectionURL)
        // do not send anything back
    }

    func connection(for session: Session) -> WebConnection? {
        // find database connection by the url
        // convert database object to the Connection
        nil
    }

    func update(_ connection: WebConnection, with session: Session) {

    }

    func save(_ connection: WebConnection) {
        // update or create a database connection
        // update the fields
        // save the database
    }

    func canHandle(request: Request) -> Bool {
        fatalError("canHandle(request:) has not been implemented")
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
