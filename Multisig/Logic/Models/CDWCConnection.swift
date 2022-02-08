//
//  CDWCConnection.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 08.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

extension CDWCConnection {

    /// Type of the remote peer in this connection
    var remotePeerType: ConnectionPeerType {
        get {
            ConnectionPeerType(rawValue: remote_rawPeerType) ?? .unknown
        }
        set {
            remote_rawPeerType = newValue.rawValue
        }
    }

    /// Current connection status
    var connectionStatus: ConnectionStatus {
        get {
            ConnectionStatus(rawValue: rawConnectionStatus) ?? .unknown
        }
        set {
            rawConnectionStatus = newValue.rawValue
        }
    }

    // TODO: placeholders for the future methods

    // connection identifier - what is it? wcurl?

    // get all connections

    // get all expired connections (to remove it)?

    // get connection by wallet connect session

    // create new connection

    // delete connection

    // update connection with network, address

    // convert to/from WalletConnect objects (ClientMeta, Session, WCURL, etc.)
}

enum ConnectionPeerType: Int16 {
    /// connection to a dapp via wallet connect
    case dapp = 0

    /// connection to an external wallet via wallet connect
    case wallet = 1

    /// connection to a Gnosis Safe Web app via wallet connect
    case gnosisSafeWeb = 2

    /// compatibility for future versions
    case unknown = -1
}

enum ConnectionStatus: Int16 {
    /// connection is not established yet
    case pending = 0

    /// connection established
    case connected = 1

    /// user rejected the connection request
    case rejected = 2

    /// the connection disconnected
    case disconnected = 3

    /// connection is past the expiration type
    case expired = 4

    /// user ignored the connection request
    case canceled = 5

    /// compatibility for future versions
    case unknown = -1
}
