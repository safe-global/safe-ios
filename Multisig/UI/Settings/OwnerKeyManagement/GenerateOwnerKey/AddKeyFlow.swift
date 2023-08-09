//
//  AddKeyFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit


/// Basis for flows that add private key
///
/// 1. Intro screen
/// 2. Override didIntro() to implement actual key input
/// 3. Call didGetKey() at some point to continue
/// 4. Enter Name screen
/// 5. importKey checks if the key already exist or continue
/// 6. Override doImport() to save key and entered name
/// 7. (optional) override didImport() to do any further action with the added key
/// 8. Create Passcode flow
/// 9. Key added screen and based on user choice we show create delegate key flow
/// 10. didDelegateKeySetup to end the flow or override to add additional steps
///
class AddKeyFlow: UIFlow {
    var createPasscodeFlow: CreatePasscodeFlow!
    var keyParameters: AddKeyParameters!

    var factory: AddKeyFlowFactory
    /// Constructor
    /// - Parameters:
    ///   - factory: screen factory
    ///   - completion: completion block called when flow ends. Argument is `true` when flow successful.
    init(factory: AddKeyFlowFactory, completion: @escaping (Bool) -> Void) {
        self.factory = factory
        super.init(completion: completion)
    }

    override func start() {
        intro()
    }

    func intro() {
        let introVC = factory.intro { [unowned self] in
            didIntro()
        }
        show(introVC)
    }

    func didIntro() {
        // to override
    }

    func didGetKey() {
        enterName()
    }

    func enterName() {
        assert(keyParameters != nil)
        let nameVC = factory.enterName(parameters: keyParameters!) { [unowned self] name in
            keyParameters.name = name
            importKey()
        }
        show(nameVC)
    }

    func importKey() {
        guard let keyParameters = keyParameters else {
            assertionFailure("Missing key arguments")
            return
        }

        let existingKey = try! KeyInfo.firstKey(address: keyParameters.address)
        guard existingKey == nil else {
            App.shared.snackbar.show(error: GSError.KeyAlreadyImported())
            stop(success: false)
            return
        }

        let success = doImport()

        guard success, let _ = try? KeyInfo.firstKey(address: keyParameters.address) else {
            stop(success: false)
            return
        }

        AppSettings.hasShownImportKeyOnboarding = true

        didImport()
    }

    func doImport() -> Bool {
        // to override
        false
    }

    func didImport() {
        createPasscode()
    }

    func createPasscode() {
        createPasscodeFlow = CreatePasscodeFlow(completion: { [unowned self] _ in
            createPasscodeFlow = nil
            keyAdded()
        })
        push(flow: createPasscodeFlow)
    }

    func keyAdded() {
        guard let address = keyParameters?.address,
                let type = keyParameters?.type,
                let name = keyParameters?.name else {
            assertionFailure("Missing key arguments")
            return
        }

        let vc = factory.keyNotification(for: address, name: name, type: type) { [weak self] in
            self?.didDelegateKeySetup()
        }

        show(vc)
    }

    func didDelegateKeySetup() {
        stop(success: true)
    }

    override func stop(success: Bool) {
        if success {
            App.shared.snackbar.show(message: "Owner key successfully added")
        }
        super.stop(success: success)
    }
}

class AddKeyParameters {
    var address: Address
    var name: String?
    var type: KeyType!
    var badgeName: String {
        type.badgeName
    }

    init(address: Address, name: String?, type: KeyType) {
        self.address = address
        self.name = name
        self.type = type
    }
}

class AddKeyFlowFactory {
    func intro(completion: @escaping () -> Void) -> AddKeyOnboardingViewController {
        let introVC = AddKeyOnboardingViewController()
        introVC.completion = completion
        return introVC
    }

    func enterName(parameters: AddKeyParameters, completion: @escaping (_ name: String) -> Void) -> EnterAddressNameViewController {
        let enterNameVC = EnterAddressNameViewController()
        enterNameVC.actionTitle = "Add"
        enterNameVC.descriptionText = "Choose a name for the owner key. The name is only stored locally and will not be shared with us or any third parties."
        enterNameVC.screenTitle = "Enter Key Name"
        enterNameVC.trackingEvent = .enterKeyName
        enterNameVC.placeholder = "Enter name"
        enterNameVC.name = parameters.name
        enterNameVC.address = parameters.address
        enterNameVC.badgeName = parameters.badgeName
        enterNameVC.completion = completion
        return enterNameVC
    }    
    
    func details(keyInfo: KeyInfo, completion: @escaping () -> Void) -> OwnerKeyDetailsViewController {
        OwnerKeyDetailsViewController(keyInfo: keyInfo, completion: completion)
    }

    func keyNotification(for address: Address,
                         name: String,
                         type: KeyType,
                         completion: @escaping () -> ()) -> KeyNotificationViewController {
        KeyNotificationViewController(address: address,
                               name: name,
                               type: type,
                               completion: completion)
    }
}

