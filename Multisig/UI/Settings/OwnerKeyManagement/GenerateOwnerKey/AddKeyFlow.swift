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
/// 5. Override doImport() to save key and entered name
/// 6. (optional) override didImport()
/// 7. Create Passcode screen
/// 8. (optional) override didCreatePasscode()
class AddKeyFlow: UIFlow {
    var createPasscodeFlow: CreatePasscodeFlow!
    var factory: AddKeyFlowFactory
    var keyName: String?
    var keyAddress: Address?
    var keyType: KeyType!
    /// Constructor
    /// - Parameters:
    ///   - badge: image name for a 'type' of the key in the identicons
    ///   - factory: screen factory
    ///   - completion: completion block called when flow ends. Argument is `true` when flow successful.
    init(keyType: KeyType, factory: AddKeyFlowFactory, completion: @escaping (Bool) -> Void) {
        self.factory = factory
        self.keyType = keyType
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

    func didGet(key: Address) {
        self.keyAddress = key
        enterName()
    }

    func enterName() {
        assert(keyAddress != nil)
        let parameters = AddKeyParameters(
            address: keyAddress!,
            keyName: nil,
            badgeName: keyType.imageName
        )
        let nameVC = factory.enterName(parameters: parameters) { [unowned self] name in
            keyName = name
            importKey()
        }
        show(nameVC)
    }

    func importKey() {
        assert(keyAddress != nil)
        let existingKey = try! KeyInfo.firstKey(address: keyAddress!)
        guard existingKey == nil else {
            App.shared.snackbar.show(error: GSError.KeyAlreadyImported())
            stop(success: false)
            return
        }

        let success = doImport()

        guard success, let _ = try? KeyInfo.firstKey(address: keyAddress!) else {
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

    func didCreatePasscode() {
        stop(success: true)
    }

    func keyAdded() {
        assert(keyAddress != nil)
        assert(keyName != nil)
        let vc = factory.keyAdded(address: keyAddress!, name: keyName!, keyType: keyType) { [unowned self] in
            stop(success: true)
        }

        show(vc)
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
        enterNameVC.trackingEvent = parameters.keyNameTrackingEvent
        enterNameVC.placeholder = "Enter name"
        enterNameVC.name = parameters.keyName
        enterNameVC.address = parameters.address
        enterNameVC.badgeName = parameters.badgeName
        enterNameVC.completion = completion
        return enterNameVC
    }    
    
    func details(keyInfo: KeyInfo, completion: @escaping () -> Void) -> OwnerKeyDetailsViewController {
        OwnerKeyDetailsViewController(keyInfo: keyInfo, completion: completion)
    }

    func keyAdded(address: Address,
                  name: String,
                  keyType: KeyType,
                  completion: @escaping () -> ()) -> KeyAddedViewController {
        KeyAddedViewController(address: address,
                               name: name,
                               keyType: keyType,
                               completion: completion)
    }
}

