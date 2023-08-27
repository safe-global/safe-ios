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

class WebSocketWrapper: WebSocketConnecting, WebSocketDelegate {
    let webSocket: WebSocket

    var request: URLRequest
    public var isConnected: Bool = false
    public var onConnect: (() -> Void)?
    public var onDisconnect: ((Error?) -> Void)?
    public var onText: ((String) -> Void)?

    init(webSocket: WebSocket) {
        self.webSocket = webSocket
        self.request = webSocket.request
    }

    func connect() {
        webSocket.connect()
    }

    func disconnect() {
        webSocket.disconnect()
    }

    func write(string: String, completion: (() -> Void)?) {
        webSocket.write(string: string, completion: completion)
    }

    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let _):
            if let onConnect {
                onConnect()
            }
            break
        case .disconnected(let foo, let bar):
            if let onDisconnect {
                onDisconnect(foo)
            }
        case .text(let text):
            if let onText {
                onText(text)
            }
        default:
            LogService.shared.debug("didReceive(): event: \(event)")
        }
    }
}

struct SocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        let request = URLRequest(url: url)
        let webSocket =  WebSocket(request: request)
        let websocketWrapper = WebSocketWrapper(webSocket: webSocket)
        webSocket.delegate = websocketWrapper
        return websocketWrapper
    }
}
