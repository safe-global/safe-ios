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
    private var name: String!
    
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
            enterOwnerName()
        })
        
        show(controller, sender: self)
    }
    
    func enterOwnerName() {
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
            self.name = name
            importOwnerKey()
        }
        show(enterNameVC, sender: self)
    }
    
    func importOwnerKey() {
        let success = OwnerKeyController.importKey(connection: connection, wallet: wallet, name: name)
        if success {
            showCreatePasscode()
        } else {
            disconnect(connection: connection)
        }
    }
    
    func showCreatePasscode() {
        let createPasscodeVC = CreatePasscodeController { [unowned self] in
            dismiss(animated: true) { [unowned self] in
                showKeyImportedConfirmation()
            }
        }
        guard let createPasscodeVC = createPasscodeVC else {
            showKeyImportedConfirmation()
            return
        }
        present(createPasscodeVC, animated: true)
    }
    
    func showKeyImportedConfirmation() {
        show(self.createKeyAddedView(address: address, name: name), sender: nil)
    }

    func createKeyAddedView(address: Address, name: String) -> WalletConnectKeyAddedViewController {
        let keyAddedVC = WalletConnectKeyAddedViewController()
        keyAddedVC.completion = { [weak self] in
            self?.showSuccessMessage()
        }
        keyAddedVC.accountAddress = address
        keyAddedVC.accountName = name

        return keyAddedVC
    }
    
    func showSuccessMessage() {
        App.shared.snackbar.show(message: "The key added successfully")
        self.completion()
    }
    
    func disconnect(connection: WebConnection) {
        WebConnectionController.shared.userDidDisconnect(connection)
        self.completion()
        return
    }
}

