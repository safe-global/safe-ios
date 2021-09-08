//
//  WalletConnectSafesServerController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 08.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

class WalletConnectSafesServerController: WalletConnectServerController {
    static let shared = WalletConnectSafesServerController()

    override init() {
        super.init()
        connectingNotification = .wcConnectingSafeServer
        disconnectingNotification = .wcDidDisconnectSafeServer
        didFailToConnectNotificatoin = .wcDidFailToConnectSafeServer
        didConnectNotificatoin = .wcDidConnectSafeServer
        didDisconnectNotificatoin = .wcDidDisconnectSafeServer
    }

    override func createSession(wcurl: WCURL) {
        WCSession.create(wcurl: wcurl)
    }

    override func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        let walletMeta = Session.ClientMeta(name: "Gnosis Safe",
                                            description: "The most trusted platform to manage digital assets.",
                                            icons: [URL(string: "https://gnosis-safe.io/app/favicon.ico")!],
                                            url: URL(string: "https://gnosis-safe.io")!)

        guard let safe = try? Safe.getSelected(),
              let address = safe.address,
              let chain = safe.chain
        else {
            // we can't get address or network in the local database, we're closing connection.
            denySession(clientMeta: walletMeta, displayMessage: nil, completion: completion)
            return
        }

        // Right now WalletConnect library expects chainId to be Int type.
        guard let selectedSafeChainId = Int(chain.id!) else {
            denySession(clientMeta: walletMeta,
                        displayMessage: "Selected safe chain is not supported yet.",
                        completion: completion)
            return
        }

        let walletInfo = Session.WalletInfo(
            approved: true,
            accounts: [address],
            chainId: selectedSafeChainId,
            peerId: UUID().uuidString,
            peerMeta: walletMeta)

        completion(walletInfo)
    }

    func updatePendingTransactions() {
        DispatchQueue.main.async {
            guard let pendingTransactions = try? WCPendingTransaction.getAll() else { return }

            for pendingTx in pendingTransactions {
                // stop monitoring pending WalletConnect transactions after 24h
                // remove legacy pending transactions without safeTxHash
                guard let safeTxHash = pendingTx.safeTxHash,
                      Date().timeIntervalSince(pendingTx.created!) < 60 * 60 * 24 else {
                    pendingTx.delete()
                    continue
                }

                let wcSession = pendingTx.session!
                let session = try! Session.from(wcSession)
                let chainId = wcSession.safe!.chain!.id!

                DispatchQueue.global().async { [unowned self] in
                    App.shared.clientGatewayService.asyncTransactionDetails(id: safeTxHash,
                                                                            chainId: chainId) { result in
                        guard case .success(let transaction) = result,
                              let txHash = transaction.txHash,
                              // it might happen that pendingTx is removed, but the object still exists
                              let requestId = pendingTx.requestId,
                              let response = try? Response(url: session.url, value: txHash, id: requestId) else {
                            return
                        }

                        self.server.send(response)

                        DispatchQueue.main.async {
                            let nonce = pendingTx.nonce!
                            pendingTx.delete()
                            App.shared.snackbar.show(message: "WalletConnect transaction with nonce \(nonce) is executed. Please return back to the browser.")
                        }
                    }
                }
            }
        }
    }
}
