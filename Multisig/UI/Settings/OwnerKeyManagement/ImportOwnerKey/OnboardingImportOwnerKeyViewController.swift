//
//  OnboardingImportOwnerKeyViewController.swift
//  Multisig
//
//  Created by Moaaz on 1/21/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingImportOwnerKeyViewController: AddKeyOnboardingViewController {
    convenience init(completion: @escaping () -> Void) {
        self.init(
            cards: [
                .init(image: UIImage(named: "ico-onboarding-import-key-1"),
                      title: "How does it work?",
                      body: "Enter the private key or seed phrase of your owner key controlling your Safe. Your owner key will be imported into this app. You can then confirm proposed transactions on the go."),

                .init(image: UIImage(named: "ico-onboarding-import-key-2"),
                      title: "How secure is that?",
                      body: "We only store your private key. We do not store your seed phrase in the app.",
                      link: .init(title: "How is a private key stored on mobile?", url: URL(string: "https://help.gnosis-safe.io/en/articles/4866738-how-are-private-keys-stored-on-gnosis-safe-mobile")!)),

                .init(image: UIImage(named: "ico-onboarding-import-key-3"),
                      title: "Is my wallet supported?",
                      body: "You can use your seed phrase from MetaMask or hardware wallet. We support private keys from any wallet in a hexadecimal 64 characters format. Importing the key will not show the balance for Ether or other assets from your MetaMask or hardware wallet.")],
            viewTrackingEvent: .importOwnerOnboarding,
            completion: completion
        )
        navigationItem.title = "Import Owner Key"
    }

    @objc override func didTapNextButton(_ sender: Any) {
        showEnterSecret()
    }

    var privateKey: PrivateKey?
    var isDerivedFromSeed: Bool = false

    func showEnterSecret() {
        let enterSecretVC = EnterKeyOrSeedPhraseViewController()
        enterSecretVC.completion = { [unowned self, unowned enterSecretVC] in
            if let rootNode = enterSecretVC.seedNode {
                showDerivedAddressPicker(rootNode)
            } else if let privateKey = enterSecretVC.privateKey {
                isDerivedFromSeed = false
                self.privateKey = privateKey
                keyParameters = AddKeyParameters(keyName: nil, address: privateKey.address)
                showEnterName()
            }
        }
        show(enterSecretVC, sender: self)
    }

    func showDerivedAddressPicker(_ rootNode: HDNode) {
        let pickDerivedKeyVC = KeyPickerController(node: rootNode)
        pickDerivedKeyVC.completion = { [unowned pickDerivedKeyVC, unowned self] in
            guard let privateKey = pickDerivedKeyVC.privateKey else {
                return
            }
            self.privateKey = privateKey
            isDerivedFromSeed = true
            keyParameters = AddKeyParameters(keyName: nil, address: privateKey.address)
            showEnterName()
        }
        show(pickDerivedKeyVC, sender: self)
    }

    func showEnterName() {
        guard let keyParameters = keyParameters as? AddLedgerKeyParameters else { return }

        let enterNameVC = EnterAddressNameViewController()
        enterNameVC.actionTitle = "Import"
        enterNameVC.descriptionText = "Choose a name for the owner key. The name is only stored locally and will not be shared with Gnosis or any third parties."
        enterNameVC.screenTitle = "Enter Key Name"
        enterNameVC.trackingEvent = .enterKeyName
        enterNameVC.placeholder = "Enter name"
        enterNameVC.name = keyParameters.keyName
        enterNameVC.address = keyParameters.address
        enterNameVC.badgeName = KeyType.deviceImported.imageName

        enterNameVC.completion = { [unowned self] name in
            keyParameters.keyName = name
            
            guard importKey(name: name) else {
                return
            }
            showCreatePasscode()
        }

        show(enterNameVC, sender: self)
    }

    func importKey(name: String) -> Bool {
        guard let privateKey = privateKey else {
            return false
        }
        if (try? KeyInfo.firstKey(address: privateKey.address)) != nil {
            return false
        }
        let success = OwnerKeyController.importKey(
            privateKey,
            name: name,
            isDrivedFromSeedPhrase: isDerivedFromSeed)
        if success {
            AppSettings.hasShownImportKeyOnboarding = true
        }
        return success
    }

    override func didCreatePasscode() {
        showSuccessMessage()
    }
}
