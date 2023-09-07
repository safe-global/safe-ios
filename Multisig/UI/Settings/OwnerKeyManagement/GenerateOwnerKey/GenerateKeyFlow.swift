//
//  GenerateKeyFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

/// Flow for generating a new private key
///
/// Screen sequence:
///
/// 1. Intro (in superclass)
/// 2. Key is generated
/// 3. Enter Name (in superclass)
/// 4. Create Passcode (in superclass)
/// 5. Backup Key
/// 6. Add Key as Safe Owner
/// 6.1. Add as new owner OR
/// 6.2. Replace existing owner
/// 7. If user selected 'open tx details' then flow closes.
/// 7.1. Otherwise, Key Details screen
class GenerateKeyFlow: AddKeyFlow {
    var flowFactory: GenerateKeyFactory {
        factory as! GenerateKeyFactory
    }

    var safe: Safe?

    var backupFlow: BackupFlow!
    var addOwnerFlow: AddOwnerFlow!
    var replaceOwnerFlow: ReplaceOwnerFlow!

    var parameters: GenerateKeyParameters? {
        keyParameters as? GenerateKeyParameters
    }

    init(completion: @escaping (Bool) -> Void) {
        super.init(factory: GenerateKeyFactory(), completion: completion)
    }

    override func didIntro() {
        let privateKey = OwnerKeyController.generate()
        keyParameters = GenerateKeyParameters(address: privateKey.address, keyName: nil, privateKey: privateKey)
        didGetKey()
    }

    override func doImport() -> Bool {
        guard let privateKey = parameters?.privateKey,
              let name = parameters?.name else {
            assertionFailure("Missing key arguments")
            return false
        }

        return OwnerKeyController.importKey(privateKey, name: name, type: .deviceGenerated, isDerivedFromSeedPhrase: true)
    }

    func backup() {
        guard let mnemonic = parameters?.privateKey?.mnemonic else {
            assertionFailure("No mnemonic found")
            return
        }

        backupFlow = BackupFlow(mnemonic: mnemonic) { [unowned self] _ in
            backupFlow = nil
            addKeyAsOwner()
        }
        push(flow: backupFlow)
    }

    func addKeyAsOwner() {
        guard let address = parameters?.address else {
            assertionFailure("Missing key arguments")
            return
        }

        safe = try? Safe.getSelected()
        guard let safe = safe else {
            didAddKeyAsOwner()
            return
        }

        if safe.isReadOnly {
            let vc = flowFactory.inviteToAddOwner { [unowned self] in
                let vc = flowFactory.shareAddKeyAsOwnerLink(owner: address, safe: safe) { [unowned self] in
                    stop(success: true)
                    return
                }

                show(vc)
            } onSkip: { [unowned self] in
                didAddKeyAsOwner()
            }
            show(vc)

        } else {
            let addVC = flowFactory.addAsOwner { [unowned self] in
                addOwner()
            } replaced: { [unowned self] in
                replaceOwner()
            } skipped: { [unowned self] in
                didAddKeyAsOwner()
            }
            show(addVC)
        }
    }

    func addOwner() {
        guard let address = parameters?.address else {
            assertionFailure("Missing key arguments")
            return
        }
        addOwnerFlow = AddOwnerFlow(newOwner: address, safe: safe!) { [unowned self] skippedTxDetails in
            addOwnerFlow = nil
            didAddKeyAsOwner(openKeyDetails: skippedTxDetails)
        }
        push(flow: addOwnerFlow)
    }

    func replaceOwner() {
        replaceOwnerFlow = ReplaceOwnerFlow(newOwner: parameters!.address, safe: safe!) { [unowned self] skippedTxDetails in
            replaceOwnerFlow = nil
            didReplaceKeyAsOwner(openKeyDetails: skippedTxDetails)
        }
        push(flow: replaceOwnerFlow)
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
        guard let address = parameters?.address else {
            assertionFailure("Missing key arguments")
            return
        }

        navigationController.setNavigationBarHidden(false, animated: true)
        let key = try? KeyInfo.firstKey(address: address)
        assert(key != nil)
        let keyVC = flowFactory.details(keyInfo: key!) { [unowned self] in
            stop(success: true)
        }
        show(keyVC)
    }

    override func didDelegateKeySetup() {
        backup()
    }
}

class GenerateKeyFactory: AddKeyFlowFactory {
    override func intro(completion: @escaping () -> Void) -> AddKeyOnboardingViewController {
        let introVC = super.intro(completion: completion)
        introVC.cards = [
            .init(image: UIImage(named: "ico-onboarding-import-key-1"),
                  title: "How does it work?",
                  body: "To use this app as an owner in the Safe Account, you can create a key and add it as an owner of your Safe Account. When you tap Next, the app will create a new private key from a new unique seed phrase."),

                .init(image: UIImage(named: "ico-onboarding-import-key-2"),
                      title: "How secure is that?",
                      body: "The owner key and the seed phrase are stored in the device's secure store - iOS Keychain.",
                      link: .init(title: "How is a private key stored on mobile?", url: App.configuration.help.keySecurityURL)),

                .init(image: UIImage(named: "ico-onboarding-import-key-3"),
                      title: "How to export?",
                      body: "To export your owner key or seed phrase, navigate to the key details.")]
        introVC.viewTrackingEvent = .generateOwnerOnboarding
        introVC.navigationItem.title = "Create Owner Key"
        introVC.navigationItem.largeTitleDisplayMode = .never
        return introVC
    }

    func inviteToAddOwner(share: @escaping () -> Void, onSkip: @escaping () -> ()) -> CreateInviteOwnerIntroViewController {
        let introVC = CreateInviteOwnerIntroViewController(onShare: share, onSkip: onSkip)
        ViewControllerFactory.makeTransparentNavigationBar(introVC)
        return introVC
    }

    func shareAddKeyAsOwnerLink(owner: Address, safe: Safe, onFinish: @escaping () -> Void) -> UIViewController {
        let vc = ShareAddOwnerLinkViewController(owner: owner,
                                                 safe: safe,
                                                 onFinish: onFinish)

        ViewControllerFactory.makeTransparentNavigationBar(vc)
        ViewControllerFactory.addCloseButton(vc)

        return vc
    }

    func addAsOwner(added: @escaping () -> Void, replaced: @escaping () -> Void, skipped: @escaping () -> Void) -> AddKeyAsOwnerIntroViewController {
        let introVC = AddKeyAsOwnerIntroViewController()
        ViewControllerFactory.makeTransparentNavigationBar(introVC)
        introVC.onAdd = added
        introVC.onReplace = replaced
        introVC.onSkip = skipped
        return introVC
    }
}

class GenerateKeyParameters: AddKeyParameters {
    var privateKey: PrivateKey?

    init(address: Address, keyName: String?, privateKey: PrivateKey?) {
        self.privateKey = privateKey
        super.init(address: address, name: keyName, type: KeyType.deviceGenerated)
    }
}
