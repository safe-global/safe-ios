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

struct SignatureRequestError: CustomNSError {
    static let errorDomain: String = "io.gnosis.safe.webconnection.eth_sign"

    var errorCode: Int
    var message: String
    var cause: Error? = nil

    var errorUserInfo: [String: Any]  {
        var result = [NSLocalizedDescriptionKey: message]
        if let error = cause {
            result[NSUnderlyingErrorKey] = error
        }
        return result
    }

    static let invalidMessageParameter = SignatureRequestError(errorCode: -1, message: "Message parameter invalid. Expected a data.")

}

class WCKeysRequestsHandler: RequestHandler {
    weak var connectionController: WebConnectionController?

    func canHandle(request: Request) -> Bool {
        request.name == "eth_sign"
    }

    func handle(request: Request) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                handle(request: request)
            }
            return
        }

        guard let controller = connectionController else {
            // respond with 'internal error'
            return
        }
        // validate the request

        // convert request to eth_sign request
        let hexMessage: String
        let address: Address
        do {
            // get address
            let addressString = try request.parameter(of: AddressString.self, at: 0)
            address = addressString.address
            // get message
            hexMessage = try request.parameter(of: String.self, at: 1)
        } catch {
//            let error = SignatureRequestError.
            // respond with 'invalidParams'
        }

        guard let message = Data(exactlyHex: hexMessage) else {
            throw SignatureRequestError.invalidMessageParameter
            // respond with 'invalid Params'
        }


        // find a connection by request url
        guard let connection = controller.connection(for: request.url) else {
            // respond with 'connection closed' or something?
            return
        }

        // check that the connection's accounts contains requested address
        // find key info with the account (or check that it exists)
        guard connection.accounts.contains(address), KeyInfo.firstKey(address: address) != nil else {
            // respond with 'invalid account' or 'account not found'
            return
        }

        // show signature view controller
        let signatureVC = SignatureRequestViewController()
        signatureVC.connection = connection
        signatureVC.controller = connectionController
        signatureVC.request = WebConnectionSignatureRequest(account: address, message: message)

        // canceled - respond with rejection
        // rejected - respond with rejection
        // signed - respond with signature

//        guard let wcKeySession = WCKeySession.get(topic: request.url.topic),
//              let session = try? Session.from(wcKeySession),
//              let walletInfo = session.walletInfo else {
//                  server.send(try! Response(request: request, error: .requestRejected))
//
//                  return
//              }
//
//        if request.method == "eth_sign" {
//            // present incoming key request controller
//            DispatchQueue.main.async {
//                guard let address = try? request.parameter(of: AddressString.self, at: 0),
//                      let keyInfo = try? KeyInfo.keys(addresses: [address.address]).first,
//                      let message = try? request.parameter(of: String.self, at: 1),
//                      let chain = Chain.by("\(walletInfo.chainId)") else {
//                          self.server.send(try! Response(request: request, error: .requestRejected))
//                          return
//                      }
//
//                // TODO: Adjust for use in the controller
////                let controller = SignatureRequestViewController(dAppMeta: session.dAppInfo.peerMeta,
////                                                                    keyInfo: keyInfo,
////                                                                    message: message,
////                                                                    chain: chain)
////
////                controller.onReject = { [unowned self] in
//                    self.server.send(try! Response(request: request, error: .requestRejected))
////                }
////
////                controller.onSign = { [unowned self] signature in
////                    self.server.send(try! Response(url: session.url, value: signature, id: request.id!.description))
////                }
//
////                let sceneDelegate = UIApplication.shared.connectedScenes.first!.delegate as! SceneDelegate
////                let vc = ViewControllerFactory.modalWithRibbon(viewController: controller, storedChain: chain)
////                sceneDelegate.present(vc)
//            }
//        }
    }
}
