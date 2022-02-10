//
//  CDWCConnection.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 08.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

/// CoreData object to persist information about the connections to other wallets and dapps
extension CDWCConnection {

    /// Type of the remote peer in this connection
    var remotePeerType: WebConnectionPeerType {
        get {
            WebConnectionPeerType(rawValue: remote_rawPeerType) ?? .unknown
        }
        set {
            remote_rawPeerType = newValue.rawValue
        }
    }

    /// Current connection status
    var connectionStatus: WebConnectionStatus {
        get {
            WebConnectionStatus(rawValue: rawConnectionStatus) ?? .unknown
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

