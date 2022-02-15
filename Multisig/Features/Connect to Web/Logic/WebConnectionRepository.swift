//
// Created by Dmitry Bespalov on 10.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Responsible for back-and-forth between the in-memory WebConnection-related objects and persisted CoreData objects.
class WebConnectionRepository {

    // -1 values are 'marker' or 'sentinel' values that indicate that the database's primitve value is nil.
    private static let CHAIN_ID_NIL: Int64 = -1
    private static let REQUEST_ID_INT_NIL = -1
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

    func connection(url: WebConnectionURL) -> WebConnection? {
        guard let cdConnection = CDWCConnection.connection(by: url.absoluteString) else { return nil }
        return connection(from: cdConnection)
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

        // update pending request
        if let request = connection.pendingRequest {
            let cdRequest = cdConnection.pendingRequest ?? CDWCRequest(context: App.shared.coreDataStack.viewContext)
            update(cdRequest: cdRequest, with: request)
            cdConnection.pendingRequest = cdRequest
        } else {
            cdConnection.pendingRequest = nil
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


    private func update(cdRequest: CDWCRequest, with other: WebConnectionRequest) {
        cdRequest.id_int = Int64(other.id.intValue ?? Self.REQUEST_ID_INT_NIL)
        cdRequest.id_string = other.id.stringValue
        cdRequest.id_double = other.id.doubleValue ?? Self.REQUEST_ID_DOUBLE_NIL
    }

    func request(from other:CDWCRequest) -> WebConnectionRequest? {
        if other.id_double != Self.REQUEST_ID_DOUBLE_NIL {
            return WebConnectionRequest(id: WebConnectionRequestId(doubleValue: other.id_double))
        } else if other.id_int != Self.REQUEST_ID_INT_NIL {
            return WebConnectionRequest(id: WebConnectionRequestId(intValue: Int(other.id_int)))
        } else if let value = other.id_string {
            return WebConnectionRequest(id: WebConnectionRequestId(stringValue: value))
        } else {
            return nil
        }
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
        let accounts = (other.keys ?? NSSet()).allObjects.map { $0 as! KeyInfo }.map(\.address)
        let localPeer = other.localPeer.flatMap(peer(from:))
        let remotePeer = other.remotePeer.flatMap(peer(from:))
        let pendingRequest = other.pendingRequest.flatMap(request(from:))
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
            pendingRequest: pendingRequest,
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

        let result = WebConnectionPeerInfo(
                peerId: peerId,
                peerType: peerType,
                role: role,
                url: url,
                name: name,
                description: peerDescription,
                icons: icons,
                deeplinkScheme: deeplinkScheme
        )
        return result
    }


}
