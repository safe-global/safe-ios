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
    var flowFactory: ImportKeyFlowFactory {
        factory as! ImportKeyFlowFactory
    }

    var parameters: ImportKeyParameters? {
        keyParameters as? ImportKeyParameters
    }

    init(completion: @escaping (Bool) -> Void) {
        super.init(factory: ImportKeyFlowFactory(), completion: completion)
    }

    override func didIntro() {
        enterSecret()
    }

    func enterSecret() {
        let enterVC = flowFactory.enterSecret { [unowned self] privateKey in
            keyParameters = ImportKeyParameters(address: privateKey.address,
                                                name: nil,
                                                source: .privateKey,
                                                privateKey: privateKey)
            didGetKey()
        } completionSeed: { [unowned self] seedNode in
            pickAccount(seedNode)
        }
        show(enterVC)
    }

    func pickAccount(_ node: HDNode) {
        let pickerVC = flowFactory.derivedAccountPicker(node: node) { [unowned self] privateKey in
            keyParameters = ImportKeyParameters(address: privateKey.address,
                                                name: nil,
                                                source: .seed,
                                                privateKey: privateKey)
            didGetKey()
        }
        show(pickerVC)
    }

    override func doImport() -> Bool {
        guard let privateKey = parameters?.privateKey,
              let name = parameters?.name,
              let source = parameters?.source else {
            assertionFailure("Missing key arguments")
            return false
        }
        
        return OwnerKeyController.importKey(privateKey,
                                            name: name,
                                            type: .deviceImported,
                                            isDerivedFromSeedPhrase: source == .seed)
    }
}

class ImportKeyFlowFactory: AddKeyFlowFactory {
    override func intro(completion: @escaping () -> Void) -> AddKeyOnboardingViewController {
        let introVC = super.intro(completion: completion)
        introVC.cards = [
            .init(image: UIImage(named: "ico-onboarding-import-key-1"),
                  title: "How does it work?",
                  body: "Enter the private key or seed phrase of your owner key controlling your Safe Account. Your owner key will be imported into this app. You can then confirm proposed transactions on the go."),
            
                .init(image: UIImage(named: "ico-onboarding-import-key-2"),
                      title: "How secure is that?",
                      body: "We only store your private key. We do not store your seed phrase in the app.",
                      link: .init(title: "How is a private key stored on mobile?", url: App.configuration.help.keySecurityURL)),
            
                .init(image: UIImage(named: "ico-onboarding-import-key-3"),
                      title: "Is my wallet supported?",
                      body: "You can use your seed phrase from MetaMask or hardware wallet. We support private keys from any wallet in a hexadecimal 64 characters format. Importing the key will not show the balance for Ether or other assets from your MetaMask or hardware wallet.")]
        introVC.viewTrackingEvent = .importOwnerOnboarding
        introVC.navigationItem.title = "Import Owner Key"
        introVC.navigationItem.largeTitleDisplayMode = .never
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
        let viewModel = SelectOwnerAddressViewModel(rootNode: node)
        let pickDerivedKeyVC = KeyPickerController(viewModel: viewModel)
        pickDerivedKeyVC.completion = { [unowned pickDerivedKeyVC] in
            let key = pickDerivedKeyVC.privateKey!
            completion(key)
        }
        return pickDerivedKeyVC
    }
}

class ImportKeyParameters: AddKeyParameters {
    var privateKey: PrivateKey?
    var source: KeySource?

    init(address: Address, name: String?, source: KeySource?, privateKey: PrivateKey?) {
        self.source = source
        self.privateKey = privateKey
        super.init(address: address, name: name, type: KeyType.keystone)
    }

    enum KeySource {
        case privateKey
        case seed
    }
}

