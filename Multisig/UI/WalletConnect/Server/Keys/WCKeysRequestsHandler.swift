//
//  WCKeysRequestsHandler.swift
//  WCKeysRequestsHandler
//
//  Created by Andrey Scherbovich on 09.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

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

        guard let wcKeySession = WCKeySession.get(topic: request.url.topic) else {
            server.send(try! Response(request: request, error: .requestRejected))
            return
        }

        if request.method == "eth_sign" {
            // TODO: implement
        }
    }
}
