//
//  StartWalletConnectionViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class StartWalletConnectionViewController: PendingWalletActionViewController, WebConnectionObserver {
    var onSuccess: (_ connection: WebConnection) -> Void = { _ in }

    private var chain: Chain!
    private var connection: WebConnection!
    private var keyInfo: KeyInfo?

    convenience init(wallet: WCAppRegistryEntry, chain: Chain, keyInfo: KeyInfo? = nil) {
        self.init(namedClass: PendingWalletActionViewController.self)
        self.wallet = wallet
        self.chain = chain
        self.keyInfo = keyInfo
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "Connecting to \(wallet.name)..."
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //TODO: add tracking here
        guard connection == nil else { return }
        do {
            connection = try WebConnectionController.shared.connect(wallet: wallet, chainId: chain.id.flatMap(Int.init))
            WebConnectionController.shared.attach(observer: self, to: connection)
            openWallet()
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
            doCancel()
        }
    }

    func openWallet() {
        if let link = wallet.connectLink(from: connection.connectionURL) {
            LogService.shared.debug("WC: Opening \(link.absoluteString)")
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
                UIApplication.shared.open(link, options: [:]) { success in
                    guard let self = self else { return }
                    if !success {
                        App.shared.snackbar.show(message: "Failed to open the wallet. Please choose a different one.")
                        self.didTapCancel(self)
                    }
                }
            }
        } else {
            App.shared.snackbar.show(message: "Failed to open the wallet. Please choose a different one.")
            WebConnectionController.shared.userDidDisconnect(connection)
        }
    }

    func didUpdate(connection: WebConnection) {
        self.connection = connection
        switch connection.status {
        case .opened:
            guard checkCorrectAccount() else { return }
            guard checkCorrectChain() else { return }

            if let keyInfo = keyInfo, OwnerKeyController.updateKey(keyInfo, connection: connection, wallet: wallet) {
                App.shared.snackbar.show(message: "Key connected successfully")
            }

            self.dismiss(animated: true) { [weak self] in
                self?.onSuccess(connection)
            }
        case .final:
            if let string = connection.lastError {
                App.shared.snackbar.show(message: string)
            }
            doCancel()
        default:
            // do nothing
            break
        }
    }

    func checkCorrectAccount() -> Bool {
        if let keyInfo = keyInfo, !connection.accounts.contains(keyInfo.address) {
            App.shared.snackbar.show(message: "Unexpected address. Please connnect to account \(keyInfo.address.ellipsized()).")
            WebConnectionController.shared.userDidDisconnect(connection)
            return false
        } else if keyInfo == nil, let account = connection.accounts.first, let existing = (try? KeyInfo.firstKey(address: account)) {
            let name = existing.displayName.prefix(30)
            App.shared.snackbar.show(message: "Address '\(account.ellipsized())' already exists with name '\(name)'. Please connect another account.")
            WebConnectionController.shared.userDidDisconnect(connection)
            return false
        } else {
            return true
        }
    }

    func checkCorrectChain() -> Bool {
        if let chain = chain,
           let connectedChainId = connection.chainId,
           let selectedChainId = chain.id,
           String(connectedChainId) != selectedChainId {
            App.shared.snackbar.show(message: "Connected to unexpected chain. Please connect to \(chain.name!).")
            WebConnectionController.shared.userDidDisconnect(connection)
            return false
        }
        return true
    }

    deinit {
        WebConnectionController.shared.detach(observer: self)
    }

    override func didTapCancel(_ sender: Any) {
        if let connection = connection {
            WebConnectionController.shared.userDidCancel(connection)
        } else {
            doCancel()
        }
    }

    func doCancel() {
        dismiss(animated: true) { [weak self] in
            self?.onCancel()
        }
    }
}
