//
//  WCRequestsHandler.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 27.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
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
            print("REQUEST: \(request.jsonString)")
            guard let wcRequest = try? request.parameter(of: WCSendTransactionRequest.self, at: 0),
                  var transaction = Transaction(wcRequest: wcRequest),
                  let signingKeyAddress = App.shared.settings.signingKeyAddress else {
                // TODO: send error response
                return
            }
            let hash = EthHasher.hash(transaction.encodeTransactionData(for: wcRequest.from))
            transaction.safeTxHash = HashString(hash)

            // TODO: make proper checks here
            let signature = try! Signer.sign(hash: hash)

            let createTxRequest = CreateTransactionRequest(
                safe: wcRequest.from,
                sender: AddressString(signingKeyAddress)!,
                signature: signature.value,
                transaction: transaction)

            try! App.shared.safeTransactionService.createTransaction(request: createTxRequest)
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
}
