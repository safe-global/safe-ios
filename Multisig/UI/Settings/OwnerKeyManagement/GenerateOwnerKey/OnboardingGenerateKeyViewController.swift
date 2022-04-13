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
        showEnterName()
    }
     
    func showEnterName() {
        let vc = EnterAddressNameViewController()
        vc.actionTitle = "Save"
        vc.descriptionText = "Choose a name for the owner key. The name is only stored locally and will not be shared with Gnosis or any third parties."
        vc.screenTitle = "Enter Key Name"
        vc.trackingEvent = .enterKeyName
        vc.placeholder = "Enter name"
        vc.address = privateKey.address
        vc.badgeName = KeyType.deviceGenerated.imageName
        vc.completion = { [unowned self] name in
            importKey(name: name)
            showCreatePasscode()
        }
        show(vc, sender: self)
    }

    func importKey(name: String) {
        guard OwnerKeyController.importKey(privateKey, name: name, isDrivedFromSeedPhrase: true),
              let keyInfo = try? KeyInfo.keys(addresses: [privateKey.address]).first else {
            return
        }
        AppSettings.hasShownImportKeyOnboarding = true
        self.keyInfo = keyInfo
    }

    func showCreatePasscode() {
        if App.shared.auth.isPasscodeSetAndAvailable {
            showBackupIntro()
            return
        }
        let passcodeVC = CreatePasscodeViewController()
        passcodeVC.navigationItem.hidesBackButton = true
        passcodeVC.hidesHeadline = false
        passcodeVC.completion = { [unowned self] in
            showBackupIntro()
        }
        show(passcodeVC, sender: self)
    }

    func showBackupIntro() {
        let backupVC = BackupIntroViewController()
        backupVC.backupCompletion = { [unowned self] startBackup in
            if startBackup {
                showSeedPhrase()
            } else {
                showKeyDetails()
            }
        }
        show(backupVC, sender: self)
    }

    func showSeedPhrase() {
        let exportVC = ExportViewController()
        exportVC.privateKey = privateKey.keyData.toHexStringWithPrefix()
        exportVC.seedPhrase = privateKey.mnemonic.map { $0.split(separator: " ").map(String.init) }
        // TODO: show verify seed phrase on completion
        show(exportVC, sender: self)

        showVerifySeedPhrase()
    }

    func showVerifySeedPhrase() {
        let verifyVC = VerifyPhraseViewController()
        verifyVC.phrase = privateKey.mnemonic.map { $0.split(separator: " ").map(String.init) } ?? []
        verifyVC.completion = { [unowned self] in
            showBackupSuccess()
        }
        show(verifyVC, sender: self)
    }

    func showBackupSuccess() {
        let successVC = SuccessViewController(
            titleText: "Your key is backed up!",
            bodyText: "If you lose your phone, you can recover this key with the seed phrase you just backed up.",
            doneTitle: "OK, great",
            trackingEvent: nil
        )
        successVC.onDone = { [unowned self] in
            showKeyDetails()
        }
        show(successVC, sender: self)
    }

    func showKeyDetails() {
        let detailsVC = OwnerKeyDetailsViewController(keyInfo: keyInfo!, completion: self.completion)
        show(detailsVC, sender: self)

        showSuccessMessage()
    }

    func showSuccessMessage() {
        let message = "The key successfully created. Add it to a Safe on desktop and then restart the mobile app."
        App.shared.snackbar.show(message: message)
    }
}
