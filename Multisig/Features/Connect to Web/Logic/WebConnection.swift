//
// Created by Dmitry Bespalov on 10.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class WebConnection {
    /// Identifier of the connection. Also a URL for establishing the connection. Required.
    var connectionURL: WebConnectionURL

    /// Current state of the connection
    var status: WebConnectionStatus = .initial

    /// Currently selected chain id. Required.
    var chainId: Int? = nil

    /// Currently selected account addresses. Empty for pending connections.
    var accounts: [Address] = []

    /// Date when the connection was established. Nil if the connection pending.
    var createdDate: Date? = nil

    /// Date when the connection will expire. Nil if the connection pending.
    var expirationDate: Date? = nil

    /// Date of last activity on the connection. Activity means receiving or sending any requests to the remote peer. Nil if connection is pending.
    var lastActivityDate: Date? = nil

    /// Information about the 'self' or this application. Nil before connection is established.
    var localPeer: WebConnectionPeerInfo? = nil

    /// Information about the remote application. Nil if not yet fetched.
    var remotePeer: WebConnectionPeerInfo? = nil

    var pendingRequest: WebConnectionRequest? = nil

    init(connectionURL: WebConnectionURL) {
        self.connectionURL = connectionURL
    }

    init(connectionURL: WebConnectionURL, status: WebConnectionStatus, chainId: Int?, accounts: [Address], createdDate: Date?, expirationDate: Date?, lastActivityDate: Date?, localPeer: WebConnectionPeerInfo?, remotePeer: WebConnectionPeerInfo?, pendingRequest: WebConnectionRequest?) {
        self.connectionURL = connectionURL
        self.status = status
        self.chainId = chainId
        self.accounts = accounts
        self.createdDate = createdDate
        self.expirationDate = expirationDate
        self.lastActivityDate = lastActivityDate
        self.localPeer = localPeer
        self.remotePeer = remotePeer
        self.pendingRequest = pendingRequest
    }
}

enum WebConnectionStatus: Int16 {
    case initial 
    
    case handshaking

    case approving
    case approved
    case rejected 
    case canceled 

    case opened 
    case closed 

    case updateReceived 
    case updateSent 

    case changingNetwork 
    case changingAccount 
    case disconnecting 

    case expired 

    case requestReceived 
    case requestProcessing 
    case responseSent 

    case final 

    /// compatibility for future versions
    case unknown = -1
}
