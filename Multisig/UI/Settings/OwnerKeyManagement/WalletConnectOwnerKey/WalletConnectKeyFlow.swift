//
//  WalletConnectKeyFlow.swift
//  Multisig
//
//  Created by Mouaz on 11/2/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WalletConnectKeyFlow: AddKeyFlow {
    var flowFactory: WalletConnectKeyFlowFactory {
        factory as! WalletConnectKeyFlowFactory
    }

    var parameters: AddWalletConnectKeyParameters? {
        keyParameters as? AddWalletConnectKeyParameters
    }

    init(completion: @escaping (Bool) -> Void) {
        super.init(factory: WalletConnectKeyFlowFactory(), completion: completion)
    }

    override func didIntro() {
        selectWallet()
    }

    func selectWallet() {
        let vc = SelectWalletViewController(completion: { [unowned self] wallet, connection in
            guard let address = connection.accounts.first else {
                App.shared.snackbar.show(error: GSError.WCConnectedKeyMissingAddress())
                return
            }

            keyParameters = AddWalletConnectKeyParameters(address: address,
                                                          name: nil,
                                                          connection: connection,
                                                          wallet: wallet)
            didGetKey()
        })

        show(vc)
    }

    override func doImport() -> Bool {
        guard let connection = parameters?.connection,
              let name = parameters?.name else {
            assertionFailure("Missing key arguments")
            return false
        }

        guard OwnerKeyController.importKey(connection: connection,
                                           wallet: parameters?.wallet,
                                           name: name) else {
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
        introVC.navigationItem.largeTitleDisplayMode = .never

        return introVC
    }
}

class AddWalletConnectKeyParameters: AddKeyParameters {
    var connection: WebConnection!
    var wallet: WCAppRegistryEntry?

    init(address: Address, name: String?, connection: WebConnection, wallet: WCAppRegistryEntry?) {
        self.connection = connection
        self.wallet = wallet
        super.init(address: address, name: name, type: KeyType.walletConnect)
    }
}
