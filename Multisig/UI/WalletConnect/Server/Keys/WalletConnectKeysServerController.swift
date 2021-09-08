//
//  WalletConnectKeysServerController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 08.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

protocol WalletConnectKeysServerControllerDelegate: AnyObject {
    func shouldStart(session: Session, completion: ([KeyInfo]) -> Void)
}

class WalletConnectKeysServerController: WalletConnectServerController {
    weak var delegate: WalletConnectKeysServerControllerDelegate?

    override init() {
        super.init()
        connectingNotification = .wcConnectingKeyServer
        disconnectingNotification = .wcDidDisconnectKeyServer
        didFailToConnectNotificatoin = .wcDidFailToConnectKeyServer
        didConnectNotificatoin = .wcDidConnectKeyServer
        didDisconnectNotificatoin = .wcDidDisconnectKeyServer
    }

    override func createSession(wcurl: WCURL) {
        //WCSession.create(wcurl: wcurl)
    }

    override func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        delegate?.shouldStart(session: session) { keys in
            // TODO: finish
        }
    }
}
