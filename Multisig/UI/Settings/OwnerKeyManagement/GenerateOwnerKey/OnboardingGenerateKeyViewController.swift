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
        keyParameters = AddKeyParameters(
                address: privateKey.address,
                keyName: nil,
                badgeName: KeyType.deviceGenerated.imageName
        )
        enterName()
    }

    override func doImportKey() -> Bool {
        guard let keyParameters = keyParameters else {
            return false
        }
        guard OwnerKeyController.importKey(privateKey, name: keyParameters.keyName!, isDrivedFromSeedPhrase: true),
              let keyInfo = try? KeyInfo.keys(addresses: [privateKey.address]).first else {
            return false
        }
        self.keyInfo = keyInfo
        return true
    }

    override func didCreatePasscode() {
        startBackupFlow()
    }

    var backupFlow: BackupFlow!

    func startBackupFlow() {
        guard let navigationController = navigationController else { return }
        backupFlow = BackupFlow(
            mnemonic: mnemonic,
            navigationController: navigationController,
            completion: { [unowned self] _ in
                backupFlow = nil
                startAddKeyAsOwnerIfPossible()
            })
        backupFlow.start()
    }

    func startAddKeyAsOwnerIfPossible() {
        if self.canAddKeyAsOwner() {
            self.startAddKeyAsOwner()
        } else {
            self.showKeyDetails()
        }
    }

    func canAddKeyAsOwner() -> Bool {
        guard let safe = try? Safe.getSelected() else { return false }
        return !safe.isReadOnly
    }

    func startAddKeyAsOwner() {
        let onFlowFinished: (() -> Void)? = { [weak self] in
            self?.dismiss(animated: true) {
                self?.showKeyDetails()
            }
        }

        let introVC = AddKeyAsOwnerIntroViewController(keyInfo: keyInfo)
        introVC.onAdd = onFlowFinished
        introVC.onReplace = onFlowFinished
        introVC.onSkip = onFlowFinished

        ViewControllerFactory.addCloseButton(introVC)

        show(introVC, sender: self)
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
