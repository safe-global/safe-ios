//
//  OnboardingConnectOwnerKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingConnectOwnerKeyViewController: AddKeyOnboardingViewController {

    class AddWCKeyParameters: AddKeyParameters {
        var connection: WebConnection
        var wallet: WCAppRegistryEntry?

        init(address: Address, keyName: String?, connection: WebConnection, wallet: WCAppRegistryEntry?) {
            self.connection = connection
            self.wallet = wallet
            super.init(address: address, keyName: keyName, badgeName: KeyType.walletConnect.imageName)
        }
    }

    convenience init(completion: @escaping () -> Void) {
        self.init(
                cards: [
                    .init(image: UIImage(named: "ico-onboarding-import-key-1"),
                            title: "How does it work?",
                            body: "You can connect an owner key from another wallet. You will be asked to select it from a list of already installed wallets on your phone or you can display a QR code and scan it with another wallet."),

                    .init(image: UIImage(named: "ico-onboarding-import-key-2"),
                            title: "How secure is that?",
                            body: "WalletConnect is a secure protocol for exchanging messages. Gnosis Safe app will not get access to your private key stored in your wallet."),

                    .init(image: UIImage(named: "ico-onboarding-import-key-3"),
                            title: "Is my wallet supported?",
                            body: "You wallet needs to support the WalletConnect protocol.")
                ],
                viewTrackingEvent: .connectOwnerOnboarding,
                completion: completion
        )
        navigationItem.title = "Connect Owner Key"
    }

    @objc override func didTapNextButton(_ sender: Any) {
        let controller = SelectWalletViewController(completion: { [unowned self] wallet, connection in
            guard let address = connection.accounts.first else {
                App.shared.snackbar.show(error: GSError.WCConnectedKeyMissingAddress())
                return
            }
            self.keyParameters = AddWCKeyParameters(
                    address: address,
                    keyName: connection.remotePeer?.name,
                    connection: connection,
                    wallet: wallet
            )
            enterName()
        })

        show(controller, sender: self)
    }

    override func doImportKey() -> Bool {
        guard let keyParameters = keyParameters as? AddWCKeyParameters else {
            return false
        }
        guard OwnerKeyController.importKey(connection: keyParameters.connection, wallet: keyParameters.wallet, name: keyParameters.keyName!) else {
            disconnect(connection: keyParameters.connection)
            return false
        }
        return true
    }

    override func didCreatePasscode() {
        showAddPushNotifications()
    }

    func showAddPushNotifications() {
        guard let keyParameters = keyParameters else {
            return
        }
        let addPushesVC = WalletConnectKeyAddedViewController()
        addPushesVC.completion = { [weak self] in
            self?.showSuccessMessage()
        }
        addPushesVC.accountAddress = keyParameters.address
        addPushesVC.accountName = keyParameters.keyName

        show(addPushesVC, sender: nil)
    }

    func disconnect(connection: WebConnection) {
        WebConnectionController.shared.userDidDisconnect(connection)
        self.completion()
    }
}
