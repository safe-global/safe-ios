//
//  WCKeysRequestsHandler.swift
//  WCKeysRequestsHandler
//
//  Created by Andrey Scherbovich on 09.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift
import UIKit

class WCKeysRequestsHandler: RequestHandler {
    private weak var server: Server!

    init(server: Server) {
        self.server = server
    }

    let supportedWalletConnectRequests = [
        "eth_sign"
    ]

    func canHandle(request: Request) -> Bool {
        return supportedWalletConnectRequests.contains(request.method)
    }

    func handle(request: Request) {
        dispatchPrecondition(condition: .notOnQueue(.main))

        guard let wcKeySession = WCKeySession.get(topic: request.url.topic),
              let session = try? Session.from(wcKeySession),
              let walletInfo = session.walletInfo else {
                  server.send(try! Response(request: request, error: .requestRejected))

                  return
              }

        if request.method == "eth_sign" {
            // present incoming key request controller
            DispatchQueue.main.async {
                guard let address = try? request.parameter(of: AddressString.self, at: 0),
                      let keyInfo = try? KeyInfo.keys(addresses: [address.address]).first,
                      let message = try? request.parameter(of: String.self, at: 1),
                      let chain = Chain.by("\(walletInfo.chainId)") else {
                          self.server.send(try! Response(request: request, error: .requestRejected))
                          return
                      }

                let controller = SignatureRequestViewController(dAppMeta: session.dAppInfo.peerMeta,
                                                                    keyInfo: keyInfo,
                                                                    message: message,
                                                                    chain: chain)

                controller.onReject = { [unowned self] in
                    self.server.send(try! Response(request: request, error: .requestRejected))
                }

                controller.onSign = { [unowned self] signature in
                    self.server.send(try! Response(url: session.url, value: signature, id: request.id!.description))
                }

                let sceneDelegate = UIApplication.shared.connectedScenes.first!.delegate as! SceneDelegate
                let vc = ViewControllerFactory.modalWithRibbon(viewController: controller, storedChain: chain)
                sceneDelegate.present(vc)
            }
        }
    }
}
