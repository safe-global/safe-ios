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
        if request.method == "eth_sendTransaction" {
            preconditionFailure("eth_sendTransaction not implemented yet")
        } else if request.method == "gs_multi_send" {
            // TODO: do we need to support it?
            preconditionFailure("gs_multi_send not supported")
        } else {
            DispatchQueue.global().async { [unowned self] in
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
}
