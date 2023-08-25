//
//  WebSocketFactory.swift
//  Multisig
//
//  Created by Mouaz on 2/22/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import Starscream
import WalletConnectRelay

extension WebSocket: WebSocketConnecting {
    public var isConnected: Bool {
        false
    }

    public var onConnect: (() -> Void)? {
        get {
            nil
        }
        set(newValue) {

        }
    }

    public var onDisconnect: ((Error?) -> Void)? {
        get {
            nil
        }
        set(newValue) {

        }
    }

    public var onText: ((String) -> Void)? {
        get {
            nil
        }
        set(newValue) {

        }
    }
}

struct SocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        let request = URLRequest(url: url)
        return WebSocket(request: request)
    }
}
