//
//  OnboardingGenerateKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingGenerateKeyViewController: AddKeyOnboardingViewController {
    private lazy var mnemonic: String = {
        // 16 bit = 12 words
        let seed = Data.randomBytes(length: 16)!
        return BIP39.generateMnemonicsFromEntropy(entropy: seed)!
    }()

    private lazy var privateKey: PrivateKey = {
        try! PrivateKey(mnemonic: mnemonic, pathIndex: 0)
    }()

    private var keyInfo: KeyInfo?

    convenience init(completion: @escaping () -> Void) {
        self.init(
            cards: [
                .init(image: UIImage(named: "ico-onboarding-import-key-1"),
                      title: "How does it work?",
                      body: "To use this app as an owner in the Gnosis Safe, you can create a key and add it as an owner of your Safe. When you tap Next, the app will create a new private key from a new unique seed phrase."),

                .init(image: UIImage(named: "ico-onboarding-import-key-2"),
                      title: "How secure is that?",
                      body: "The owner key and the seed phrase are stored in the device's secure store - iOS Keychain.",
                      link: .init(title: "How is a private key stored on mobile?", url: URL(string: "https://help.gnosis-safe.io/en/articles/4866738-how-are-private-keys-stored-on-gnosis-safe-mobile")!)),

                .init(image: UIImage(named: "ico-onboarding-import-key-3"),
                      title: "How to export?",
                      body: "To export your owner key or seed phrase, navigate to the key details.")
            ],
            viewTrackingEvent: .generateOwnerOnboarding,
            completion: completion
        )
        navigationItem.title = "Create Owner Key"
    }

    @objc override func didTapNextButton(_ sender: Any) {
        keyParameters = AddKeyParameters(keyName: nil, address: privateKey.address)
        showEnterName()
    }
     
    func showEnterName() {
        guard let keyParameters = keyParameters else { return }

        let enterNameVC = EnterAddressNameViewController()
        enterNameVC.actionTitle = "Save"
        enterNameVC.descriptionText = "Choose a name for the owner key. The name is only stored locally and will not be shared with Gnosis or any third parties."
        enterNameVC.screenTitle = "Enter Key Name"
        enterNameVC.trackingEvent = .enterKeyName
        enterNameVC.placeholder = "Enter name"
        enterNameVC.name = keyParameters.keyName
        enterNameVC.address = keyParameters.address
        enterNameVC.badgeName = KeyType.deviceGenerated.imageName
        enterNameVC.completion = { [unowned self] name in
            keyParameters.keyName = name
            guard importKey(name: name) else { return }
            showCreatePasscode()
        }
        show(enterNameVC, sender: self)
    }

    func importKey(name: String) -> Bool {
        if (try? KeyInfo.firstKey(address: privateKey.address)) != nil {
            App.shared.snackbar.show(error: GSError.KeyAlreadyImported())
            return false
        }

        guard OwnerKeyController.importKey(privateKey, name: name, isDrivedFromSeedPhrase: true),
              let keyInfo = try? KeyInfo.keys(addresses: [privateKey.address]).first else {
            return false
        }
        AppSettings.hasShownImportKeyOnboarding = true
        self.keyInfo = keyInfo
        return true
    }

    override func didCreatePasscode() {
        startBackupFlow()
    }

    // modally present the BackupController
    // and when flow finishes - continue with key details
    func startBackupFlow() {
        let backupController = BackupController(showIntro: true, seedPhrase: mnemonic)
        backupController.onComplete = { [weak self] in
            self?.showKeyDetails()
        }
        backupController.onCancel = { [weak self] in
            self?.showKeyDetails()
        }
        show(backupController, sender: self)
    }

    func showKeyDetails() {
        let detailsVC = OwnerKeyDetailsViewController(keyInfo: keyInfo!, completion: self.completion)
        show(detailsVC, sender: self)
        showSuccessMessage()
    }

    override func finish() {
        // empty, completion is called after key details is dismissed.
    }
}
