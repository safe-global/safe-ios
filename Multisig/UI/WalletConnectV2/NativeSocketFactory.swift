//
//  NativeSocketFactory.swift
//  Multisig
//
//  Created by Dirk Jäckel on 11.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectRelay

public enum NativeSocketError: Error {
    case errorWithCode(URLSessionWebSocketTask.CloseCode)
}

public class NativeSocket: NSObject, WebSocketConnecting {

    private var socket: URLSessionWebSocketTask? = nil

    init(withURL url: URL) {
        self.isConnected = false
        self.request = URLRequest(url: url)

        super.init()

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        self.socket = session.webSocketTask(with: url)
    }

    // MARK: - WebSocketConnecting

    public var isConnected: Bool

    public var onConnect: (() -> Void)?

    public var onDisconnect: ((Error?) -> Void)?

    public var onText: ((String) -> Void)?

    public var request: URLRequest

    public func connect() {
        socket?.resume()
    }

    public func disconnect() {
        socket?.cancel()
    }

    public func write(string: String, completion: (() -> Void)?) {
        let message = URLSessionWebSocketTask.Message.string(string)
        LogService.shared.debug("===> \(message)")
        socket?.send(message) { error in
            if let error = error {
                LogService.shared.debug("===> NativeSocket sending error: \(error)")
            }

            if let completion = completion {
                completion()
            }
        }
    }

    func receiveMessage() {
        socket?.receive(completionHandler: { [weak self] result in

            switch result {
            case .failure(let error):
                LogService.shared.debug("<=== NativeSocket Error receiving: \(error)")

                // If its failing because the conneciton closed by itself, try to reconnect
                let error = error as NSError
                if error.code == 57 && error.domain == "NSPOSIXErrorDomain" {
                    self?.disconnect()
                }

            case .success(let message):
                switch message {
                case .string(let messageString):
                    LogService.shared.debug("<=== message: \(messageString)")
                    if let onText = self?.onText {
                        onText(messageString)
                    }

                case .data(let data):
                    LogService.shared.debug("<=== data: \(data.description)")
                    if let onText = self?.onText {
                        onText(data.description)
                    }

                default:
                    LogService.shared.debug("<=== NativeSocket received unknown data")
                }
            }

            if self?.isConnected == true {
                self?.receiveMessage()
            }
        })
    }
}

extension NativeSocket: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true

        if let onConnect = onConnect {
            onConnect()
        }

        receiveMessage()
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false

        if let onDisconnect = onDisconnect {
            if closeCode != URLSessionWebSocketTask.CloseCode.normalClosure {
                onDisconnect(NativeSocketError.errorWithCode(closeCode))
            }

            onDisconnect(nil)
        }
    }
}

struct NativeSocketFactory: WebSocketFactory {

    func create(with url: URL) -> WebSocketConnecting {
        return NativeSocket(withURL: url)
    }
}
