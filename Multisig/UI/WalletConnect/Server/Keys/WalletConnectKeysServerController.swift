//
//  WalletConnectKeysServerController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 08.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

class WalletConnectKeysServerController: WalletConnectServerController {
    static let shared = WalletConnectKeysServerController()

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

        // Show connection request overlay with a possibility to select a key (today)
        // once the key is selected, we send a completion
    }
}
