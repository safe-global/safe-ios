//
// Created by Dmitry Bespalov on 10.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Information about a participant in the connection.
class WebConnectionPeerInfo {
    /// The identifier of a communication channel. Range of values: UUID values
    var peerId: String
    var peerType: WebConnectionPeerType
    var role: WebConnectionPeerRole
    var url: URL
    var name: String
    var description: String?
    var icons: [URL]
    /// Deep link to open in order to switch to the peer's app
    var deeplinkScheme: String?

    init(peerId: String, peerType: WebConnectionPeerType, role: WebConnectionPeerRole, url: URL, name: String, description: String?, icons: [URL], deeplinkScheme: String?) {
        self.peerId = peerId
        self.peerType = peerType
        self.role = role
        self.url = url
        self.name = name
        self.description = description
        self.icons = icons
        self.deeplinkScheme = deeplinkScheme
    }
}

/// Type of a peer
enum WebConnectionPeerType: Int16 {
    /// connection to a dapp via wallet connect
    case dapp = 0

    /// connection to an external wallet via wallet connect
    case wallet = 1

    /// connection to a Gnosis Safe Web app via wallet connect
    case gnosisSafeWeb = 2

    /// 'self', or this application.
    case thisApp = 3

    /// compatibility for future versions
    case unknown = -1
}

/// Peer's role in the connection
enum WebConnectionPeerRole: Int16 {
    /// Wallet is (mostly) handler of the requests from the dapp.
    case wallet = 0
    /// Dapp is (mostly) initiator of the requests to the wallet.
    case dapp = 1
    case unknown = -1
}