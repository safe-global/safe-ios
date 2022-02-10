//
// Created by Dmitry Bespalov on 10.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class WebConnectionPeerInfo {
    var peerId: String
    var peerType: WebConnectionPeerType
    var role: WebConnectionPeerRole
    var url: URL
    var name: String
    var description: String
    var icons: [URL]
    var deeplinkScheme: String

    init(peerId: String, peerType: WebConnectionPeerType, role: WebConnectionPeerRole, url: URL, name: String, description: String, icons: [URL], deeplinkScheme: String) {
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

enum WebConnectionPeerRole: Int16 {
    case wallet = 0
    case dapp = 1
    case unknown = -1
}