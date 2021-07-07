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

        guard let wcSession = WCSession.get(topic: request.url.topic), let safe = wcSession.safe else {
            server.send(try! Response(request: request, error: .requestRejected))
            return
        }

        if request.method == "eth_sendTransaction" {

            // make transformation of incoming request into internal data types
            // and fetch information about safe from the request

            guard let wcRequest = try? request.parameter(of: WCSendTransactionRequest.self, at: 0),
                  let requestId = request.id,
                  let transaction = Transaction(wcRequest: wcRequest, safe: safe),
                  let safeInfo = try? App.shared.clientGatewayService.syncSafeInfo(safeAddress: safe.addressValue,
                                                                                   networkId: safe.network!.chainId!),
                  let importedKeysAddresses = try? KeyInfo.all().map({ $0.address })
            else {
                server.send(try! Response(request: request, error: .requestRejected))
                return
            }

            // check if safe owner is imported to initiate transactions

            let safeOwnerAddresses = Set(safeInfo.owners.map { $0.value.address })
            let importedKeysForSafe = safeOwnerAddresses.intersection(importedKeysAddresses)
            guard !importedKeysForSafe.isEmpty else {
                DispatchQueue.main.async {
                    App.shared.snackbar.show(message: "Please import Safe Owner Key to initiate WalletConnect transactions")
                }
                server.send(try! Response(request: request, error: .requestRejected))
                return
            }

            // present confirmation controller

            DispatchQueue.main.async { [unowned self] in
                let confirmationController = WCTransactionConfirmationViewController(
                    transaction: transaction,
                    safe: safe,
                    minimalNonce: safeInfo.nonce,
                    topic: request.url.topic,
                    importedKeysForSafe: [Address](importedKeysForSafe))

                confirmationController.onReject = {
                    self.server.send(try! Response(request: request, error: .requestRejected))
                }

                confirmationController.onSubmit = {
                    // transaction is successfully submitted to our backend
                    // add pending transacion for monitoring
                    DispatchQueue.main.async {
                        guard let wcSession = WCSession.get(topic: request.url.topic) else { return }
                        WCPendingTransaction.create(
                            wcSession: wcSession,
                            nonce: transaction.nonce,
                            requestId: requestId.description)
                    }
                }

                let navController = UINavigationController(rootViewController: confirmationController)
                let sceneDelegate = UIApplication.shared.connectedScenes.first!.delegate as! SceneDelegate
                sceneDelegate.present(navController)
            }
        } else {
            do {
                let rpcURL = safe.network!.authenticatedRpcUrl
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
