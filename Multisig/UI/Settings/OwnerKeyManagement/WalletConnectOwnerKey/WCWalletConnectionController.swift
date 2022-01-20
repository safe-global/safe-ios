//
//  WCWalletConnectionController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

// reconnects to external wallet via wallet connect
class WCWalletConnectionController {
    // technically it is possible to select several wallets but to finish connection with one of them
    private var walletPerTopic = [String: InstalledWallet]()
    // `wcDidConnectClient` happens when app eneters foreground. This parameter should throttle unexpected events
    private var waitingForSession = false

    var keyInfo: KeyInfo!
    weak var presenter: UIViewController!
    var completion: (Bool) -> Void = { _ in }

    func connect(keyInfo: KeyInfo, from vc: UIViewController, completion: @escaping (Bool) -> Void) {
        self.keyInfo = keyInfo
        self.presenter = vc
        self.completion = completion

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(walletConnectSessionCreated(_:)),
            name: .wcDidConnectClient,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(walletConnectDidDisconnect),
            name: .wcDidDisconnectClient,
            object: nil)

        if isConnected() {
            completion(true)
        } else {
            connect()
        }
    }

    func isConnected() -> Bool {
        let isConnected = WalletConnectClientController.shared.isConnected(keyInfo: keyInfo)
        return isConnected
    }

    private func connect() {
        if let installedWallet = keyInfo.installedWallet {
            reconnectWithInstalledWallet(installedWallet)
        } else {
            showConnectionQRCodeController()
        }
    }

    private func reconnectWithInstalledWallet(_ installedWallet: InstalledWallet) {
        // this will open the other app (wallet) async after returning.
        guard let topic = WalletConnectClientController.reconnectWithInstalledWallet(installedWallet) else {
            return
        }
        walletPerTopic[topic] = installedWallet
        waitingForSession = true
    }

    private func showConnectionQRCodeController() {
        WalletConnectClientController.showConnectionQRCodeController(from: presenter) { result in
            switch result {
            case .success(_):
                waitingForSession = true
            case .failure(let error):
                App.shared.snackbar.show(
                    error: GSError.error(description: "Could not create connection URL", error: error))
            }
        }
    }

    func hideQRCodeController() {
        if let presented = presenter.presentedViewController {
            presented.dismiss(animated: false, completion: nil)
        }
    }

    @objc private func walletConnectDidDisconnect(_ notification: Notification) {
        self.completion(false)
    }
    
    @objc private func walletConnectSessionCreated(_ notification: Notification) {
        // connected, validate connection.
        guard waitingForSession else { return }
        waitingForSession = false

        guard let session = notification.object as? Session,
              let account = Address(session.walletInfo?.accounts.first ?? ""),
              account == keyInfo.address
        else {
            WalletConnectClientController.shared.disconnect()
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // we need to update to always properly refresh session.walletInfo.peerId
            // that we use to identify if the wallet is connected
            _ = OwnerKeyController.updateKey(session: session,
                                             installedWallet: self.walletPerTopic[session.url.topic])

            // If the session is initiated with QR code, then we need to hide QR code controller
            self.hideQRCodeController()

            App.shared.snackbar.show(message: "Owner key wallet connected")

            self.completion(true)
        }
    }

}
