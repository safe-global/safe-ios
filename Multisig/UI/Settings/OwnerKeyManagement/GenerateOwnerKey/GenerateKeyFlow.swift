//
//  GenerateKeyFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit


class GenerateKeyFlow: UIFlow {
    var factory: GenerateKeyFactory
    var privateKey: PrivateKey?
    var keyName: String?
    var keyInfo: KeyInfo?

    var createPasscodeFlow: CreatePasscodeFlow!
    var backupFlow: BackupFlow!

    init(factory: GenerateKeyFactory = GenerateKeyFactory(), navigationController: UINavigationController, completion: @escaping (Bool) -> Void) {
        self.factory = factory
        super.init(navigationController: navigationController, completion: completion)
    }

    override func start() {
        intro()
    }

    func intro() {
        let introVC = factory.intro { [unowned self] in
            privateKey = OwnerKeyController.generate()
            enterName()
        }
        show(introVC)
    }

    func enterName() {
        assert(privateKey != nil)
        let parameters = AddKeyParameters(
            address: privateKey!.address,
            keyName: nil,
            badgeName: KeyType.deviceGenerated.imageName
        )
        let nameVC = factory.enterName(parameters: parameters) { [unowned self] name in
            keyName = name
            doImport()
        }
        show(nameVC)
    }

    func doImport() {
        assert(privateKey != nil)
        assert(keyName != nil)
        let existingKey = try! KeyInfo.firstKey(address: privateKey!.address)
        guard existingKey == nil else {
            App.shared.snackbar.show(error: GSError.KeyAlreadyImported())
            stop(success: false)
            return
        }

        let success = OwnerKeyController.importKey(privateKey!, name: keyName!, isDrivedFromSeedPhrase: true)
        keyInfo = try? KeyInfo.keys(addresses: [privateKey!.address]).first
        guard success, keyInfo != nil else {
            stop(success: false)
            return
        }

        AppSettings.hasShownImportKeyOnboarding = true

        didImport()
    }

    func didImport() {
        createPasscode()
    }

    func createPasscode() {
        createPasscodeFlow = CreatePasscodeFlow(navigationController: navigationController, completion: { [unowned self] _ in
            createPasscodeFlow = nil
            didCreatePasscode()
        })
        createPasscodeFlow.start()
    }

    func didCreatePasscode() {
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
        let addVC = factory.addAsOwner(keyInfo: keyInfo!) { [unowned self] in
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
        let keyVC = factory.details(keyInfo: keyInfo!) { [unowned self] in
            stop(success: true)
        }
        show(keyVC)
    }

    override func stop(success: Bool) {
        if success {
            App.shared.snackbar.show(message: "Owner key successfully added")
        }
        super.stop(success: success)
    }
}

class GenerateKeyFactory: AddKeyFlowFactory {
    func intro(completion: @escaping () -> Void) -> AddKeyOnboardingViewController {
        let introVC = AddKeyOnboardingViewController(
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

class AddKeyParameters {
    var address: Address
    var keyName: String?
    var badgeName: String
    var keyNameTrackingEvent: TrackingEvent

    init(address: Address, keyName: String?, badgeName: String, keyNameTrackingEvent: TrackingEvent = .enterKeyName) {
        self.address = address
        self.keyName = keyName
        self.badgeName = badgeName
        self.keyNameTrackingEvent = keyNameTrackingEvent
    }
}

class AddKeyFlowFactory {
    func enterName(parameters: AddKeyParameters, completion: @escaping (_ name: String) -> Void) -> EnterAddressNameViewController {
        let enterNameVC = EnterAddressNameViewController()
        enterNameVC.actionTitle = "Add"
        enterNameVC.descriptionText = "Choose a name for the owner key. The name is only stored locally and will not be shared with Gnosis or any third parties."
        enterNameVC.screenTitle = "Enter Key Name"
        enterNameVC.trackingEvent = parameters.keyNameTrackingEvent
        enterNameVC.placeholder = "Enter name"
        enterNameVC.name = parameters.keyName
        enterNameVC.address = parameters.address
        enterNameVC.badgeName = parameters.badgeName
        enterNameVC.completion = completion
        return enterNameVC
    }

}

class AddKeyFlow {

}

class CreatePasscodeFlow: UIFlow {
    var factory: PasscodeFlowFactory

    init(factory: PasscodeFlowFactory = PasscodeFlowFactory(), navigationController: UINavigationController, completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        super.init(navigationController: navigationController, completion: completion)
    }

    override func start() {
        create()
    }

    func create() {
        guard !App.shared.auth.isPasscodeSetAndAvailable else {
            stop(success: false)
            return
        }
        let createVC = factory.create { [unowned self] in
            stop(success: true)
        }
        show(createVC)
    }
}

class PasscodeFlowFactory {
    func create(completion: @escaping () -> Void) -> CreatePasscodeViewController {
        let createVC = CreatePasscodeViewController(completion)
        createVC.navigationItem.hidesBackButton = true
        return createVC
    }
}
