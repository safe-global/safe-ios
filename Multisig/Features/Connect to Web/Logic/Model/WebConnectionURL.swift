//
// Created by Dmitry Bespalov on 09.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

/// Connection URL identifies a connection and contains information for establishing the connection
struct WebConnectionURL: Hashable {
    var wcURL: WCURL

    /// Channel (topic) on which the dapp will send the connection request
    var handshakeChannelId: String {
        get { wcURL.topic }
        set { wcURL.topic = newValue }
    }

    /// WalletConnect protocol version. Default to "1"
    var protocolVersion: String {
        get { wcURL.version }
        set { wcURL.version = newValue }
    }

    /// WalletConnect bridge url
    var bridgeURL: URL {
        get { wcURL.bridgeURL }
        set { wcURL.bridgeURL = newValue }
    }

    /// Channel's communication is encrypted by the symmetric key
    var symmetricEncryptionKey: String {
        get { wcURL.key }
        set { wcURL.key = newValue }
    }

    /// String representation of the URL.
    var absoluteString: String {
        wcURL.absoluteString
    }
}

extension WebConnectionURL {
    /// Creates new url from string. The string has to be in the WalletConnect format (starts with `wc:`, etc.)
    ///
    /// Returns nil if the url string is not valid.
    ///
    /// - Parameter string: string to create a URL from.
    init?(string: String) {
        guard let url = WCURL(string) else { return nil }
        wcURL = url
    }
}
