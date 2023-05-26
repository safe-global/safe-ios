//
//  WCRequestsHandler.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 27.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

extension RequestID {
    var description: String {
        if let str = self as? String { return str }
        if let int = self as? Int { return String(int) }
        if let double = self as? Double { return String(double) }
        return "nil"
    }
}

class WCRequestsHandler: RequestHandler {
    private weak var server: Server!

    init(server: Server) {
        self.server = server
    }

    let unsupportedWalletConnectRequests = [
        "personal_sign",
        "eth_sign",
        "eth_signTypedData",
        "eth_signTransaction",
        "eth_sendRawTransaction",
        "gs_multi_send"
    ]

    func canHandle(request: Request) -> Bool {
        return !unsupportedWalletConnectRequests.contains(request.method)
    }

    func handle(request: Request) {
        dispatchPrecondition(condition: .notOnQueue(.main))

        guard let wcSession = WCSession.get(topic: request.url.topic),
              let safe = wcSession.safe,
              let session = try? Session.from(wcSession) else {
            server.send(try! Response(request: request, error: .requestRejected))
            return
        }

        if request.method == "eth_sendTransaction" {

            // make transformation of incoming request into internal data types
            // and fetch information about Safe Account from the request

            guard let wcRequest = try? request.parameter(of: WCSendTransactionRequest.self, at: 0),
                  let requestId = request.id,
                  let safeInfo = try? App.shared.clientGatewayService.syncSafeInfo(
                    safeAddress: safe.addressValue, chainId: safe.chain!.id!) else {
                server.send(try! Response(request: request, error: .requestRejected))
                return
            }

            safe.update(from: safeInfo)

            guard let transaction = Transaction(wcRequest: wcRequest, safe: safe) else {
                server.send(try! Response(request: request, error: .requestRejected))
                return
            }

            guard !safe.isReadOnly else {
                DispatchQueue.main.async {
                    App.shared.snackbar.show(message: "Please import Safe Owner Key to initiate WalletConnect transactions")
                }
                server.send(try! Response(request: request, error: .requestRejected))
                return
            }

            // present confirmation controller

            DispatchQueue.main.async { [unowned self] in
                let confirmationController = WCIncomingTransactionRequestViewController(
                    transaction: transaction,
                    safe: safe,
                    dAppName: session.dAppInfo.peerMeta.name,
                    dAppIconURL: session.dAppInfo.peerMeta.icons.first)

                confirmationController.onReject = { [unowned self] in
                    self.server.send(try! Response(request: request, error: .requestRejected))
                }

                confirmationController.onSubmit = { nonce, safeTxHash in
                    self.server.send(try! Response(url: request.url, value: safeTxHash, id: requestId))
                }

                let sceneDelegate = UIApplication.shared.connectedScenes.first!.delegate as! SceneDelegate
                sceneDelegate.present(ViewControllerFactory.modal(viewController: confirmationController))
            }
        } else {
            do {
                let rpcURL = safe.chain!.authenticatedRpcUrl
                let result = try App.shared.nodeService.rawCall(payload: request.jsonString, rpcURL: rpcURL)
                let response = try Response(url: request.url, jsonString: result)
                self.server.send(response)
            } catch {
                DispatchQueue.main.async {
                    App.shared.snackbar.show(
                        error: GSError.error(description: "Could not handle WalletConnect request", error: error)
                    )
                }
            }
        }
    }
}
