//
//  WCRequestsHandler.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 27.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

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
        "eth_sendRawTransaction"
    ]

    func canHandle(request: Request) -> Bool {
        return !unsupportedWalletConnectRequests.contains(request.method)
    }

    #warning("Finish impplementation")
    func handle(request: Request) {
        dispatchPrecondition(condition: .notOnQueue(.main))

        if request.method == "eth_sendTransaction" {
            guard let wcRequest = try? request.parameter(of: WCSendTransactionRequest.self, at: 0),
                  var transaction = Transaction(wcRequest: wcRequest),
                  // we asume that we did a check on if signing key is a safe owner during connection initialization
                  // otherwiser later server will not accept any requests
                  let signingKeyAddress = App.shared.settings.signingKeyAddress else {
                server.send(try! Response(request: request, error: .requestRejected))
                return
            }

            let hash = EthHasher.hash(transaction.encodeTransactionData(for: wcRequest.from))
            transaction.safeTxHash = HashString(hash)

            DispatchQueue.main.async { [unowned self] in
                let confirmationController =
                    WCTransactionConfirmationViewController(transaction: transaction, topic: request.url.topic)

                confirmationController.onReject = {
                    self.server.send(try! Response(request: request, error: .requestRejected))
                }

                confirmationController.onSubmit = {
                    // TODO: make proper checks here
                    let signature = try! Signer.sign(hash: hash)
                    let createTxRequest = CreateTransactionRequest(
                        safe: wcRequest.from,
                        sender: AddressString(signingKeyAddress)!,
                        signature: signature.value,
                        transaction: transaction)
                    self.submitCreateTransactionRequest(createTxRequest, topic: request.url.topic)
                }
                UIWindow.topMostController()!.present(confirmationController, animated: true)
            }
        } else if request.method == "gs_multi_send" {
            // TODO: do we need to support it?
            preconditionFailure("gs_multi_send not supported")
        } else {
            do {
                let result = try App.shared.nodeService.rawCall(payload: request.jsonString)
                let response = try Response(url: request.url, jsonString: result)
                self.server.send(response)
            } catch {
                // TODO: finish
            }
        }
    }

    private func submitCreateTransactionRequest(_ request: CreateTransactionRequest, topic: String) {
        DispatchQueue.global().async {
            try! App.shared.safeTransactionService.createTransaction(request: request)
            let nonce = request.transaction.nonce
            guard let wcSession = WCSession.get(topic: topic) else { return }
            DispatchQueue.main.async {
                WCPendingTransaction.create(wcSession: wcSession, nonce: nonce)
            }
        }
    }
}
