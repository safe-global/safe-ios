//
//  GenerateKeyFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class GenerateKeyFlow: AddKeyFlow {
    var flowFactory: GenerateKeyFactory {
        factory as! GenerateKeyFactory
    }

    var backupFlow: BackupFlow!

    init(factory: GenerateKeyFactory = GenerateKeyFactory(), navigationController: UINavigationController, completion: @escaping (Bool) -> Void) {
        super.init(badge: KeyType.deviceGenerated.imageName, factory: factory, navigationController: navigationController, completion: completion)
    }

    override func didIntro() {
        let privateKey = OwnerKeyController.generate()
        didGetKey(privateKey: privateKey)
    }

    override func doImport() -> Bool {
        assert(privateKey != nil)
        assert(keyName != nil)
        let success = OwnerKeyController.importKey(privateKey!, name: keyName!, isDrivedFromSeedPhrase: true)
        return success
    }

    override func didCreatePasscode() {
        backup()
    }

    func backup() {
        assert(privateKey?.mnemonic != nil)
        backupFlow = BackupFlow(
            mnemonic: privateKey!.mnemonic!,
            navigationController: navigationController,
            completion: { [unowned self] _ in
                backupFlow = nil
                addKeyAsOwner()
            })
        backupFlow.start()
    }

    func addKeyAsOwner() {
        assert(keyInfo != nil)
        guard canAddKeyAsOwner() else {
            didAddKey()
            return
        }
        let addVC = flowFactory.addAsOwner(keyInfo: keyInfo!) { [unowned self] in
            didAddKey()
        }
        show(addVC)
    }

    func canAddKeyAsOwner() -> Bool {
        guard let safe = try? Safe.getSelected() else { return false }
        return !safe.isReadOnly
    }

    func didAddKey() {
        assert(keyInfo != nil)
        let keyVC = flowFactory.details(keyInfo: keyInfo!) { [unowned self] in
            stop(success: true)
        }
        show(keyVC)
    }
}

class GenerateKeyFactory: AddKeyFlowFactory {
    override func intro(completion: @escaping () -> Void) -> AddKeyOnboardingViewController {
        let introVC = super.intro(completion: completion)
        introVC.cards = [
            .init(image: UIImage(named: "ico-onboarding-import-key-1"),
                  title: "How does it work?",
                  body: "To use this app as an owner in the Gnosis Safe, you can create a key and add it as an owner of your Safe. When you tap Next, the app will create a new private key from a new unique seed phrase."),

                .init(image: UIImage(named: "ico-onboarding-import-key-2"),
                      title: "How secure is that?",
                      body: "The owner key and the seed phrase are stored in the device's secure store - iOS Keychain.",
                      link: .init(title: "How is a private key stored on mobile?", url: URL(string: "https://help.gnosis-safe.io/en/articles/4866738-how-are-private-keys-stored-on-gnosis-safe-mobile")!)),

                .init(image: UIImage(named: "ico-onboarding-import-key-3"),
                      title: "How to export?",
                      body: "To export your owner key or seed phrase, navigate to the key details.")]
        introVC.viewTrackingEvent = .generateOwnerOnboarding
        introVC.navigationItem.title = "Create Owner Key"
        return introVC
    }

    func addAsOwner(keyInfo: KeyInfo, completion: @escaping () -> Void) -> AddKeyAsOwnerIntroViewController {
        let introVC = AddKeyAsOwnerIntroViewController(keyInfo: keyInfo)
        introVC.onAdd = completion
        introVC.onReplace = completion
        introVC.onSkip = completion
        introVC.navigationItem.hidesBackButton = true
        return introVC
    }

    func details(keyInfo: KeyInfo, completion: @escaping () -> Void) -> OwnerKeyDetailsViewController  {
        OwnerKeyDetailsViewController(keyInfo: keyInfo, completion: completion)
    }
}
