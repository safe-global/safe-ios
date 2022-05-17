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

    var safe: Safe?

    var backupFlow: BackupFlow!
    var addOwnerFlow: AddOwnerFlow!
    var replaceOwnerFlow: ReplaceOwnerFlow!

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
        safe = try? Safe.getSelected()
        guard safe != nil, !safe!.isReadOnly else {
            didAddKeyAsOwner()
            return
        }
        let addVC = flowFactory.addAsOwner { [unowned self] in
            addOwner()
        } replaced: { [unowned self] in
            replaceOwner()
        } skipped: { [unowned self] in
            didAddKeyAsOwner()
        }
        show(addVC)
    }

    func addOwner() {
        addOwnerFlow = AddOwnerFlow(
            newOwner: keyInfo!,
            safe: safe!,
            navigationController: navigationController) { [unowned self] skippedTxDetails in
                addOwnerFlow = nil
                didAddKeyAsOwner(openKeyDetails: skippedTxDetails)
        }
        addOwnerFlow.start()
    }

    func replaceOwner() {
        replaceOwnerFlow = ReplaceOwnerFlow(
            newOwner: keyInfo!,
            safe: safe!,
            navigationController: navigationController) { [unowned self] skippedTxDetails in
                replaceOwnerFlow = nil
                didReplaceKeyAsOwner(openKeyDetails: skippedTxDetails)
        }
        replaceOwnerFlow.start()
    }

    func didAddKeyAsOwner(openKeyDetails: Bool = true) {
        guard openKeyDetails else {
            stop(success: true)
            return
        }
        details()
    }

    func didReplaceKeyAsOwner(openKeyDetails: Bool = true) {
        guard openKeyDetails else {
            stop(success: true)
            return
        }
        details()
    }

    func details() {
        assert(keyInfo?.address != nil)
        navigationController.setNavigationBarHidden(false, animated: true)
        let key = try? KeyInfo.firstKey(address: keyInfo!.address)
        assert(key != nil)
        let keyVC = flowFactory.details(keyInfo: key!) { [unowned self] in
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

    func addAsOwner(added: @escaping () -> Void, replaced: @escaping () -> Void, skipped: @escaping () -> Void) -> AddKeyAsOwnerIntroViewController {
        let introVC = AddKeyAsOwnerIntroViewController()
        introVC.onAdd = added
        introVC.onReplace = replaced
        introVC.onSkip = skipped
        introVC.navigationItem.hidesBackButton = true
        return introVC
    }

    func details(keyInfo: KeyInfo, completion: @escaping () -> Void) -> OwnerKeyDetailsViewController {
        OwnerKeyDetailsViewController(keyInfo: keyInfo, completion: completion)
    }
}
