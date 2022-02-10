//
// Created by Dmitry Bespalov on 09.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

struct WebConnectionURL: Hashable {
    var wcURL: WCURL

    var handshakeChannelId: String {
        get { wcURL.topic }
        set { wcURL.topic = newValue }
    }

    var protocolVersion: String {
        get { wcURL.version }
        set { wcURL.version = newValue }
    }

    var bridgeURL: String {
        get { wcURL.version }
        set { wcURL.version = newValue }
    }

    var symmetricEncryptionKey: String {
        get { wcURL.key }
        set { wcURL.key = newValue }
    }
}

extension WebConnectionURL {
    init?(string: String) {
        guard let url = WCURL(string) else { return nil }
        wcURL = url
    }
}