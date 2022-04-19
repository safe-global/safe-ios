//
//  OnboardingConnectOwnerKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingConnectOwnerKeyViewController: AddKeyOnboardingViewController {
    
    private var connection: WebConnection!
    private var wallet: WCAppRegistryEntry?
    private var address: Address!

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
            self.connection = connection
            self.address = address
            self.wallet = wallet
            self.keyParameters = AddKeyParameters(keyName: connection.remotePeer?.name, address: address)
            enterOwnerName()
        })
        
        show(controller, sender: self)
    }
    
    func enterOwnerName() {
        guard let keyParameters = keyParameters else { return }
        let enterNameVC = EnterAddressNameViewController()
        enterNameVC.actionTitle = "Import"
        enterNameVC.descriptionText = "Choose a name for the owner key. The name is only stored locally and will not be shared with Gnosis or any third parties."
        enterNameVC.screenTitle = "Enter Key Name"
        enterNameVC.trackingEvent = .enterKeyName
        enterNameVC.placeholder = "Enter name"
        enterNameVC.name = keyParameters.keyName
        enterNameVC.address = keyParameters.address
        enterNameVC.badgeName = KeyType.walletConnect.imageName
        enterNameVC.completion = { [unowned self] name in
            keyParameters.keyName = name
            importOwnerKey()
        }
        show(enterNameVC, sender: self)
    }
    
    func importOwnerKey() {
        if (try? KeyInfo.firstKey(address: address)) != nil {
            App.shared.snackbar.show(error: GSError.KeyAlreadyImported())
            return
        }

        let success = OwnerKeyController.importKey(connection: connection, wallet: wallet, name: keyName)
        if success {
            showCreatePasscode()
        } else {
            disconnect(connection: connection)
        }
    }

    override func didCreatePasscode() {
        showAddPushNotifications()
    }

    func showAddPushNotifications() {
        let addPushesVC = WalletConnectKeyAddedViewController()
        addPushesVC.completion = { [weak self] in
            self?.showSuccessMessage()
        }
        addPushesVC.accountAddress = address
        addPushesVC.accountName = keyName

        show(addPushesVC, sender: nil)
    }
    
    func disconnect(connection: WebConnection) {
        WebConnectionController.shared.userDidDisconnect(connection)
        self.completion()
        return
    }
}
