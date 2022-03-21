//
//  StartWalletConnectionViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class StartWalletConnectionViewController: WalletConnectionViewController, WebConnectionObserver {
    var onSuccess: (_ connection: WebConnection) -> Void = { _ in }

    private var chain: Chain!
    private var connection: WebConnection!

    convenience init(wallet: WCAppRegistryEntry, chain: Chain) {
        self.init(namedClass: WalletConnectionViewController.self)
        self.wallet = wallet
        self.chain = chain
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
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
            onCancel()
        }
    }

    func didUpdate(connection: WebConnection) {
        switch connection.status {
        case .opened:
            onSuccess(connection)
        case .final:
            if let string = connection.lastError {
                App.shared.snackbar.show(message: string)
            }
            onCancel()
        default:
            // do nothing
            break
        }
    }

    deinit {
        WebConnectionController.shared.detach(observer: self)
    }

    override func didTapCancel(_ sender: Any) {
        if let connection = connection {
            WebConnectionController.shared.userDidCancel(connection)
        } else {
            onCancel()
        }
    }
}
