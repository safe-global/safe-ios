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
        "eth_sendRawTransaction"
    ]

    func canHandle(request: Request) -> Bool {
        return !unsupportedWalletConnectRequests.contains(request.method)
    }

    #warning("Finish impplementation")
    #warning("FIXME!!!")
    func handle(request: Request) {
        dispatchPrecondition(condition: .notOnQueue(.main))

        if request.method == "eth_sendTransaction" {
            guard let signingKeyAddress = try? KeyInfo.all().map({ $0.address.checksummed }).first else {
                DispatchQueue.main.async {
                    App.shared.snackbar.show(message: "Please import Signing Key to initiate WalletConnect transactions!")
                }
                server.send(try! Response(request: request, error: .requestRejected))
                return
            }

            guard let wcRequest = try? request.parameter(of: WCSendTransactionRequest.self, at: 0),
                  let requestId = request.id,
                  var transaction = Transaction(wcRequest: wcRequest) else {
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
                    let key = try! KeyInfo.all().first!
                    let signature = try! key.privateKey()!.sign(hash: hash)
                    let createTxRequest = CreateTransactionRequest(
                        safe: wcRequest.from,
                        sender: AddressString(signingKeyAddress)!,
                        signature: signature.hexadecimal,
                        transaction: transaction)
                    self.submitCreateTransactionRequest(createTxRequest,
                                                        topic: request.url.topic,
                                                        requestId: requestId.description)
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

    private func submitCreateTransactionRequest(_ request: CreateTransactionRequest, topic: String, requestId: String) {
        DispatchQueue.global().async {
            do {
                try App.shared.safeTransactionService.createTransaction(request: request)
                DispatchQueue.main.async {
                    App.shared.snackbar.show(message: "The transaction is submitted and can be confirmed by other owners. Once it is executed the dapp will get a response with the transaction hash.", duration: 6)
                }
            } catch {
                DispatchQueue.main.async {
                    App.shared.snackbar.show(error: GSError.CouldNotSubmitWalletConnectTransaction())
                }
            }
            let nonce = request.transaction.nonce
            guard let wcSession = WCSession.get(topic: topic) else { return }
            DispatchQueue.main.async {
                WCPendingTransaction.create(wcSession: wcSession, nonce: nonce, requestId: requestId)
            }
        }
    }
}
