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
            enterOwnerName(connection: connection, address: address, wallet: wallet)
        })
        
        show(controller, sender: self)
    }
    
    func enterOwnerName(connection: WebConnection, address: Address, wallet: WCAppRegistryEntry?) {
        let enterNameVC = EnterAddressNameViewController()
        enterNameVC.actionTitle = "Import"
        enterNameVC.descriptionText = "Choose a name for the owner key. The name is only stored locally and will not be shared with Gnosis or any third parties."
        enterNameVC.screenTitle = "Enter Key Name"
        enterNameVC.trackingEvent = .enterKeyName
        enterNameVC.placeholder = "Enter name"
        enterNameVC.name = connection.remotePeer?.name
        enterNameVC.address = address
        enterNameVC.badgeName = KeyType.walletConnect.imageName
        enterNameVC.completion = { [unowned self, unowned enterNameVC] name in
            importOwnerKey(connection: connection, wallet: wallet, name: name) { success in
                if success {
                    if App.shared.auth.isPasscodeSetAndAvailable {
                        showKeyImportedConfirmation(presenter: enterNameVC, address: address, name: name)
                    } else {
                        startPasscodeSetup(presenter: enterNameVC, address: address, name: name) { [unowned self] in
                            self.showKeyImportedConfirmation(presenter: enterNameVC, address: address, name: name)
                        }
                    }
                } else {
                    disconnect(connection: connection)
                }
            }
        }
        self.show(enterNameVC, sender: self)
    }
    
    func importOwnerKey(connection: WebConnection, wallet: WCAppRegistryEntry?, name: String, completion: (Bool) -> Void) {
        let success = OwnerKeyController.importKey(connection: connection, wallet: wallet, name: name)
        completion(success)
    }
    
    func startPasscodeSetup(presenter: UIViewController, address: Address, name: String, completion: @escaping () -> Void) {
        let createPasscodeViewController = CreatePasscodeViewController(completion)
        createPasscodeViewController.navigationItem.hidesBackButton = true
        createPasscodeViewController.hidesHeadline = false
        presenter.show(createPasscodeViewController, sender: presenter)
    }
    
    func showKeyImportedConfirmation(presenter: UIViewController, address: Address, name: String) {
        presenter.show(self.createKeyAddedView(address: address, name: name), sender: nil)
    }

    func createKeyAddedView(address: Address, name: String) -> WalletConnectKeyAddedViewController {
        let keyAddedVC = WalletConnectKeyAddedViewController()
        keyAddedVC.completion = { [weak self] in
            App.shared.snackbar.show(message: "The key added successfully")
            self?.completion()
        }
        keyAddedVC.accountAddress = address
        keyAddedVC.accountName = name

        return keyAddedVC
    }
    
    func disconnect(connection: WebConnection) {
        WebConnectionController.shared.userDidDisconnect(connection)
        self.completion()
        return
    }
}

