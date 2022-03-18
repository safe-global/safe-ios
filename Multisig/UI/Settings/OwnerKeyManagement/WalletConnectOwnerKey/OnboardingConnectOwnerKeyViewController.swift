//
//  OnboardingConnectOwnerKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingConnectOwnerKeyViewController: AddKeyOnboardingViewController {
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

            let enterNameVC = EnterAddressNameViewController()
            enterNameVC.actionTitle = "Import"
            enterNameVC.descriptionText = "Choose a name for the owner key. The name is only stored locally and will not be shared with Gnosis or any third parties."
            enterNameVC.screenTitle = "Enter Key Name"
            enterNameVC.trackingEvent = .enterKeyName

            enterNameVC.placeholder = "Enter name"
            enterNameVC.name = connection.remotePeer?.name
            enterNameVC.address = address
            enterNameVC.badgeName = KeyType.walletConnect.imageName

            enterNameVC.completion = { [unowned self] name in
                let success = OwnerKeyController.importKey(connection: connection, wallet: wallet, name: name)

                if !success {
                    self.completion()
                    return
                }

                let keyAddedVC = WalletConnectKeyAddedViewController()
                keyAddedVC.completion = { [weak self] in
                    App.shared.snackbar.show(message: "The key added successfully")
                    self?.completion()
                }
                keyAddedVC.accountAddress = address
                keyAddedVC.accountName = name

                enterNameVC.show(keyAddedVC, sender: nil)
            }

            self.show(enterNameVC, sender: self)
        })
        show(controller, sender: self)
    }
}
