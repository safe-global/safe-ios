//
//  WalletConnectKeyFlow.swift
//  Multisig
//
//  Created by Mouaz on 11/2/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WalletConnectKeyFlow: AddKeyFlow {
    private var connection: WebConnection!
    private var wallet: WCAppRegistryEntry?
    private var address: Address!

    var flowFactory: WalletConnectKeyFlowFactory {
        factory as! WalletConnectKeyFlowFactory
    }

    init(completion: @escaping (Bool) -> Void) {
        super.init(keyType: .walletConnect, factory: WalletConnectKeyFlowFactory(), completion: completion)
    }

    override func didIntro() {
        selectWallet()
    }

    func selectWallet() {
        let vc = flowFactory.selectWallet { [unowned self] connection, wallet in
            guard let address = connection.accounts.first else {
                App.shared.snackbar.show(error: GSError.WCConnectedKeyMissingAddress())
                return
            }

            self.connection = connection
            self.wallet = wallet
            didGet(key: address)
        }

        show(vc)
    }

    override func doImport() -> Bool {
        assert(connection != nil)
        assert(wallet != nil)
        assert(keyName != nil)
        assert(keyAddress != nil)
        guard OwnerKeyController.importKey(connection: connection, wallet: wallet, name: keyName!) else {
            WebConnectionController.shared.userDidDisconnect(connection)
            return false
        }

        return true
    }
}

class WalletConnectKeyFlowFactory: AddKeyFlowFactory {
    override func intro(completion: @escaping () -> Void) -> AddKeyOnboardingViewController {
        let introVC = super.intro(completion: completion)
        introVC.cards =  [
            .init(image: UIImage(named: "ico-onboarding-import-key-1"),
                    title: "How does it work?",
                    body: "You can connect an owner key from another wallet. You will be asked to select it from a list of already installed wallets on your phone or you can display a QR code and scan it with another wallet."),

            .init(image: UIImage(named: "ico-onboarding-import-key-2"),
                    title: "How secure is that?",
                    body: "WalletConnect is a secure protocol for exchanging messages. Safe app will not get access to your private key stored in your wallet."),

            .init(image: UIImage(named: "ico-onboarding-import-key-3"),
                    title: "Is my wallet supported?",
                    body: "You wallet needs to support the WalletConnect protocol.")
        ]
        introVC.viewTrackingEvent = .connectOwnerOnboarding
        introVC.navigationItem.title = "Connect Owner Key"
        return introVC
    }

    func selectWallet(completion: @escaping (_ connection: WebConnection, _ wallet: WCAppRegistryEntry?) -> Void) -> SelectWalletViewController {
        let controller = SelectWalletViewController(completion: { wallet, connection in
            completion(connection, wallet)
        })

        return controller
    }
}
