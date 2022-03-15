//
// Created by Dmitry Bespalov on 10.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Ethereum
import Solidity
import JsonRpc2

/// Responsible for back-and-forth between the in-memory WebConnection-related objects and persisted CoreData objects.
class WebConnectionRepository {

    // -1 values are 'marker' or 'sentinel' values that indicate that the database's primitve value is nil.
    private static let CHAIN_ID_NIL: Int64 = -1
    private static let REQUEST_ID_INT_NIL: Int64 = -1
    private static let REQUEST_ID_DOUBLE_NIL: Double = -1
    private static let ICONS_SEPARATOR: String = "|"

    func connections() -> [WebConnection] {
        var connections: [WebConnection] = []
        do {
            connections = try CDWCConnection.getAll().compactMap(connection(from:))
        } catch {
            LogService.shared.error("Failed to get Web Connections: \(error.localizedDescription)")
        }
        return connections
    }

    func connections(status: WebConnectionStatus) -> [WebConnection] {
        let result = CDWCConnection.connections(by: status.rawValue).compactMap(connection(from:))
        return result
    }

    func connection(url: WebConnectionURL) -> WebConnection? {
        guard let cdConnection = CDWCConnection.connection(by: url.absoluteString) else { return nil }
        return connection(from: cdConnection)
    }

    func connections(expiredAt date: Date) -> [WebConnection] {
        let result = CDWCConnection.connections(expiredAt: date).compactMap(connection(from:))
        return result
    }

    func connections(account: Address) -> [WebConnection] {
        guard let keyInfo = (try? KeyInfo.firstKey(address: account)), let cdConnections = keyInfo.connections else { return [] }
        let result = cdConnections.allObjects.compactMap { $0 as? CDWCConnection }.compactMap(connection(from:))
        return result
    }

    func delete(_ connection: WebConnection) {
        CDWCConnection.delete(by: connection.connectionURL.absoluteString)
    }

    func save(_ connection: WebConnection) {
        assert(Thread.isMainThread)

        // find or replace the object
        var cdConnection: CDWCConnection! = CDWCConnection.connection(by: connection.connectionURL.absoluteString)
        if cdConnection == nil {
            cdConnection = CDWCConnection.create()
        }
        // update the fields
        update(cdConnection: cdConnection, with: connection)

        // update local peer
        if let peer = connection.localPeer {
            let cdPeer = cdConnection.localPeer ?? CDWCPeerInfo(context: App.shared.coreDataStack.viewContext)
            update(cdPeer: cdPeer, with: peer)
            cdConnection.localPeer = cdPeer
        } else {
            cdConnection.localPeer = nil
        }

        // update remote peer info
        if let peer = connection.remotePeer {
            let cdPeer = cdConnection.remotePeer ?? CDWCPeerInfo(context: App.shared.coreDataStack.viewContext)
            update(cdPeer: cdPeer, with: peer)
            cdConnection.remotePeer = cdPeer
        } else {
            cdConnection.remotePeer = nil
        }

        // update connected keys / accounts
        if let keys = cdConnection.keys, keys.count > 0 {
            cdConnection.removeFromKeys(keys)
        }
        do {
            let keys = try KeyInfo.keys(addresses: connection.accounts)
            cdConnection.keys = NSSet(array: keys)
        } catch {
            LogService.shared.error("Failed to set connection keys: \(error)")
        }

        // save the database
        App.shared.coreDataStack.saveContext()
    }

    private func update(cdConnection: CDWCConnection, with other: WebConnection) {
        cdConnection.connectionURL = other.connectionURL.absoluteString
        cdConnection.chainId = other.chainId.map { Int64($0) } ?? Self.CHAIN_ID_NIL
        cdConnection.createdDate = other.createdDate
        cdConnection.expirationDate = other.expirationDate
        cdConnection.lastActivityDate = other.lastActivityDate
        cdConnection.status = other.status.rawValue
        cdConnection.lastError = other.lastError
        cdConnection.accounts = other.accounts.map(\.checksummed).joined(separator: ",")
    }

    private func update(cdPeer: CDWCPeerInfo, with other: WebConnectionPeerInfo) {
        cdPeer.peerId = other.peerId
        cdPeer.peerType = other.peerType.rawValue
        cdPeer.role = other.role.rawValue
        cdPeer.name = other.name
        cdPeer.peerDescription = other.description
        cdPeer.icons = other.icons.map(\.absoluteString).joined(separator: Self.ICONS_SEPARATOR)
        cdPeer.deeplinkScheme = other.deeplinkScheme
        cdPeer.url = other.url
    }

    private func connection(from other: CDWCConnection) -> WebConnection? {
        guard
            let rawConnectionURL: String = other.connectionURL,
            let connectionURL = WebConnectionURL(string: rawConnectionURL)
        else { return nil }

        let chainId: Int? = other.chainId == Self.CHAIN_ID_NIL ? nil : Int(other.chainId)
        let createdDate: Date? = other.createdDate
        let expirationDate: Date? = other.expirationDate
        let lastActivityDate: Date? = other.lastActivityDate
        let status = WebConnectionStatus(rawValue: other.status) ?? .unknown

        let accountsFromKeyInfos = (other.keys ?? NSSet()).allObjects.map { $0 as! KeyInfo }.map(\.address)
        let accountsFromStrings = (other.accounts ?? "").split(separator: ",").map(String.init).compactMap(Address.init)
        let accounts = Array(Set(accountsFromKeyInfos + accountsFromStrings))

        let localPeer = other.localPeer.flatMap(peer(from:))
        let remotePeer = other.remotePeer.flatMap(peer(from:))
        let lastError: String? = other.lastError

        let result = WebConnection(
            connectionURL: connectionURL,
            status: status,
            chainId: chainId,
            accounts: accounts,
            createdDate: createdDate,
            expirationDate: expirationDate,
            lastActivityDate: lastActivityDate,
            localPeer: localPeer,
            remotePeer: remotePeer,
            lastError: lastError
        )
        return result
    }

    private func peer(from other: CDWCPeerInfo) -> WebConnectionPeerInfo? {
        guard
            let rawIcons = other.icons,
            let name: String = other.name,
            let peerId: String = other.peerId,
            let url: URL = other.url
        else {
            return nil
        }
        let iconParts: [Substring] = rawIcons.split(separator: Character(Self.ICONS_SEPARATOR))
        let icons: [URL] = iconParts.compactMap { URL(string: String($0)) }

        let peerType = WebConnectionPeerType(rawValue: other.peerType) ?? .unknown
        let role = WebConnectionPeerRole(rawValue: other.role) ?? .unknown
        let peerDescription: String? = other.peerDescription
        let deeplinkScheme: String? = other.deeplinkScheme

         if peerType == .gnosisSafeWeb {
            return GnosisSafeWebPeerInfo(
                peerId: peerId,
                peerType: peerType,
                role: role,
                url: url,
                name: name,
                description: peerDescription,
                icons: icons,
                deeplinkScheme: deeplinkScheme)
         }

        return WebConnectionPeerInfo(
                peerId: peerId,
                peerType: peerType,
                role: role,
                url: url,
                name: name,
                description: peerDescription,
                icons: icons,
                deeplinkScheme: deeplinkScheme
        )
    }

    func save(_ request: WebConnectionRequest) {
        assert(Thread.isMainThread)
        // get request
        var existing: CDWCRequest? = nil
        if let url = request.connectionURL, let id = request.id {
            existing = cdRequest(connectionURL: url, requestId: id)
        }
        let cdRequest = existing ?? CDWCRequest.create()

        // update it
        update(cdRequest: cdRequest, with: request)

        // connect to a connection entity
        if let url = request.connectionURL, let cdConnection = CDWCConnection.connection(by: url.absoluteString) {
            cdRequest.connection = cdConnection
        }

        App.shared.coreDataStack.saveContext()
    }

    private func cdRequest(connectionURL: WebConnectionURL, requestId: WebConnectionRequestId) -> CDWCRequest? {
        CDWCRequest.request(
            url: connectionURL.absoluteString,
            id_int: requestId.intValue.map(Int64.init) ?? Self.REQUEST_ID_INT_NIL,
            id_double: requestId.doubleValue ?? Self.REQUEST_ID_DOUBLE_NIL,
            id_string: requestId.stringValue
        )
    }

    func request(connectionURL: WebConnectionURL, requestId: WebConnectionRequestId) -> WebConnectionRequest? {
        let result = cdRequest(connectionURL: connectionURL, requestId: requestId)
            .flatMap(request(from:))
        return result
    }

    private func update(cdRequest: CDWCRequest, with other: WebConnectionRequest) {
        cdRequest.id_int =  other.id?.intValue.map(Int64.init) ?? Self.REQUEST_ID_INT_NIL
        cdRequest.id_string = other.id?.stringValue
        cdRequest.id_double = other.id?.doubleValue ?? Self.REQUEST_ID_DOUBLE_NIL
        cdRequest.json = other.json
        cdRequest.method = other.method
        cdRequest.error = other.error
        cdRequest.status = other.status.rawValue
        cdRequest.createdDate = other.createdDate
    }

    fileprivate func openConnectionRequest(_ other: CDWCRequest) -> WebConnectionOpenRequest {
        let id = requestId(from: other)
        let connectionURL = other.connection?.connectionURL.flatMap { WebConnectionURL(string: $0) }
        let status = WebConnectionRequestStatus(rawValue: other.status) ?? .unknown
        let result = WebConnectionOpenRequest(
            id: id,
            method: other.method,
            error: other.error,
            json: other.json,
            status: status,
            connectionURL: connectionURL,
            createdDate: other.createdDate)
        return result
    }

    fileprivate func signatureRequest(_ other: CDWCRequest) -> WebConnectionSignatureRequest? {
        let id = requestId(from: other)
        let connectionURL = other.connection?.connectionURL.flatMap { WebConnectionURL(string: $0) }
        let status = WebConnectionRequestStatus(rawValue: other.status) ?? .unknown
        guard let json = other.json else {
            return nil
        }
        let account: Address
        let message: Data
        do {
            let data = json.data(using: .utf8)!
            let request = try JSONDecoder().decode(JsonRpc2.Request.self, from: data)
            guard request.method == "eth_sign", let eth_sign = try request.params?.convert(to: EthRpc1.eth_sign.self) else {
                return nil
            }
            let suffixBytes = Array(eth_sign.address.storage).suffix(20)
            let addressData = Data(suffixBytes)
            guard let address = Address(addressData) else {
                return nil
            }
            account = address
            message = eth_sign.message.storage
        } catch {
            LogService.shared.error("Failed to decode eth_sign request from CoreData: \(error)")
            return nil
        }
        let result = WebConnectionSignatureRequest(
                id: id,
                method: other.method,
                error: other.error,
                json: other.json,
                status: status,
                connectionURL: connectionURL,
                createdDate: other.createdDate,
                account: account,
                message: message)
        return result
    }

    fileprivate func sendTransactionRequest(_ other: CDWCRequest) -> WebConnectionSendTransactionRequest? {
        let id = requestId(from: other)
        let connectionURL = other.connection?.connectionURL.flatMap { WebConnectionURL(string: $0) }
        let status = WebConnectionRequestStatus(rawValue: other.status) ?? .unknown
        guard let json = other.json else {
            return nil
        }

        do {
            let data = json.data(using: .utf8)!
            let request = try JSONDecoder().decode(JsonRpc2.Request.self, from: data)
            guard
                request.method == "eth_sendTransaction",
                let params = try request.params?.convert(to: EthRpc1.eth_sendTransaction.self)
            else {
                return nil
            }
            let transaction = params.transaction.ethTransaction
            let result = WebConnectionSendTransactionRequest(
                    id: id,
                    method: other.method,
                    error: other.error,
                    json: other.json,
                    status: status,
                    connectionURL: connectionURL,
                    createdDate: other.createdDate,
                    transaction: transaction)
            return result
        } catch {
            LogService.shared.error("Failed to decode eth_sign request from CoreData: \(error)")
            return nil
        }
    }

    fileprivate func genericRequest(_ other: CDWCRequest) -> WebConnectionRequest? {
        let id = requestId(from: other)
        let connectionURL = other.connection?.connectionURL.flatMap { WebConnectionURL(string: $0) }
        let status = WebConnectionRequestStatus(rawValue: other.status) ?? .unknown
        let result = WebConnectionRequest(
            id: id,
            method: other.method,
            error: other.error,
            json: other.json,
            status: status,
            connectionURL: connectionURL,
            createdDate: other.createdDate
        )
        return result
    }

    func request(from other: CDWCRequest) -> WebConnectionRequest? {
        switch other.method {
        case "wc_sessionRequest":
            return openConnectionRequest(other)

        case "eth_sendTransaction":
            if let request = sendTransactionRequest(other) {
                return request
            } else {
                return genericRequest(other)
            }

        case "eth_sign":
            if let request = signatureRequest(other) {
                return request
            } else {
                return genericRequest(other)
            }

        default:
            return genericRequest(other)
        }
    }

    func requestId(from other: CDWCRequest) -> WebConnectionRequestId? {
        if other.id_double != Self.REQUEST_ID_DOUBLE_NIL {
            return WebConnectionRequestId(doubleValue: other.id_double)
        } else if other.id_int != Self.REQUEST_ID_INT_NIL {
            return WebConnectionRequestId(intValue: Int(other.id_int))
        } else if let value = other.id_string {
            return WebConnectionRequestId(stringValue: value)
        } else {
            return nil
        }
    }

    func pendingConnectionRequest(url: WebConnectionURL) -> WebConnectionOpenRequest? {
        let result = CDWCRequest
            .request(connectionURL: url, method: "wc_sessionRequest", status: .pending)
            .map(openConnectionRequest(_:))
        return result
    }

    func pendingRequests(connection: WebConnection? = nil) -> [WebConnectionRequest] {
        let cdRequests = connection == nil ?
                CDWCRequest.all(status: WebConnectionRequestStatus.pending.rawValue) :
                CDWCRequest.all(url: connection!.connectionURL.absoluteString, status: WebConnectionRequestStatus.pending.rawValue)
        let result = cdRequests.compactMap(request(from:))
        return result
    }

    func delete(request: WebConnectionRequest) {
        guard let url = request.connectionURL, let requestId = request.id else { return }
        CDWCRequest.delete(
            url: url.absoluteString,
            id_int: requestId.intValue.map(Int64.init) ?? Self.REQUEST_ID_INT_NIL,
            id_double: requestId.doubleValue ?? Self.REQUEST_ID_DOUBLE_NIL,
            id_string: requestId.stringValue
        )
    }
}
