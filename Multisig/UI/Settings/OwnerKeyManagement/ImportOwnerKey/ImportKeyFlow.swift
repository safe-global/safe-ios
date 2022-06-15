//
//  ImportKeyFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

/// Flow for importing a private key from seed phrase or plain text.
///
/// Screen sequence:
///
/// 1. Intro (in superclass)
/// 2. Enter Key or Seed
/// 2.1. If entered seed, then Pick Derived Account
/// 3. Enter Name (in superclass)
/// 4. Create Passcode (in superclass)
class ImportKeyFlow: AddKeyFlow {
    var keySource: KeySource?
    var flowFactory: ImportKeyFlowFactory {
        factory as! ImportKeyFlowFactory
    }

    enum KeySource {
        case privateKey
        case seed
    }

    init(completion: @escaping (Bool) -> Void) {
        super.init(badge: KeyType.deviceGenerated.imageName, factory: ImportKeyFlowFactory(), completion: completion)
    }

    override func didIntro() {
        enterSecret()
    }

    func enterSecret() {
        keySource = nil
        privateKey = nil
        let enterVC = flowFactory.enterSecret { [unowned self] privateKey in
            keySource = .privateKey
            didGetKey(privateKey: privateKey)
        } completionSeed: { [unowned self] seedNode in
            keySource = .seed
            pickAccount(seedNode)
        }
        show(enterVC)
    }

    func pickAccount(_ node: HDNode) {
        let pickerVC = flowFactory.derivedAccountPicker(node: node) { [unowned self] privateKey in
            didGetKey(privateKey: privateKey)
        }
        show(pickerVC)
    }

    override func doImport() -> Bool {
        assert(privateKey != nil)
        assert(keyName != nil)
        let success = OwnerKeyController.importKey(privateKey!, name: keyName!, isDrivedFromSeedPhrase: keySource == .seed)
        return success
    }
}

class ImportKeyFlowFactory: AddKeyFlowFactory {
    override func intro(completion: @escaping () -> Void) -> AddKeyOnboardingViewController {
        let introVC = super.intro(completion: completion)
        introVC.cards = [
            .init(image: UIImage(named: "ico-onboarding-import-key-1"),
                  title: "How does it work?",
                  body: "Enter the private key or seed phrase of your owner key controlling your Safe. Your owner key will be imported into this app. You can then confirm proposed transactions on the go."),
            
                .init(image: UIImage(named: "ico-onboarding-import-key-2"),
                      title: "How secure is that?",
                      body: "We only store your private key. We do not store your seed phrase in the app.",
                      link: .init(title: "How is a private key stored on mobile?", url: URL(string: "https://help.gnosis-safe.io/en/articles/4866738-how-are-private-keys-stored-on-gnosis-safe-mobile")!)),
            
                .init(image: UIImage(named: "ico-onboarding-import-key-3"),
                      title: "Is my wallet supported?",
                      body: "You can use your seed phrase from MetaMask or hardware wallet. We support private keys from any wallet in a hexadecimal 64 characters format. Importing the key will not show the balance for Ether or other assets from your MetaMask or hardware wallet.")]
        introVC.viewTrackingEvent = .importOwnerOnboarding
        introVC.navigationItem.title = "Import Owner Key"
        return introVC
    }

    func enterSecret(completionKey: @escaping (_ privateKey: PrivateKey) -> Void, completionSeed: @escaping (_ seedNode: HDNode) -> Void) -> EnterKeyOrSeedPhraseViewController {
        let enterVC = EnterKeyOrSeedPhraseViewController()
        enterVC.completion = { [unowned enterVC] in
            if let node = enterVC.seedNode {
                completionSeed(node)
            } else {
                let key = enterVC.privateKey!
                completionKey(key)
            }
        }
        return enterVC
    }

    func derivedAccountPicker(node: HDNode, completion: @escaping (_ privateKey: PrivateKey) -> Void) -> KeyPickerController {
        let pickDerivedKeyVC = KeyPickerController(node: node)
        pickDerivedKeyVC.completion = { [unowned pickDerivedKeyVC] in
            let key = pickDerivedKeyVC.privateKey!
            completion(key)
        }
        return pickDerivedKeyVC
    }
}
