//
//  AddKeyFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class AddKeyFlow: UIFlow {
    var privateKey: PrivateKey?
    var keyName: String?
    var keyInfo: AddressInfo?
    var badgeImageName: String
    var createPasscodeFlow: CreatePasscodeFlow!
    var factory: AddKeyFlowFactory

    init(badge: String, factory: AddKeyFlowFactory, navigationController: UINavigationController, completion: @escaping (Bool) -> Void) {
        self.factory = factory
        self.badgeImageName = badge
        super.init(navigationController: navigationController, completion: completion)
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

    func didGetKey(privateKey: PrivateKey) {
        self.privateKey = privateKey
        enterName()
    }

    func enterName() {
        assert(privateKey != nil)
        let parameters = AddKeyParameters(
            address: privateKey!.address,
            keyName: nil,
            badgeName: badgeImageName
        )
        let nameVC = factory.enterName(parameters: parameters) { [unowned self] name in
            keyName = name
            importKey()
        }
        show(nameVC)
    }

    func importKey() {
        assert(privateKey != nil)
        let existingKey = try! KeyInfo.firstKey(address: privateKey!.address)
        guard existingKey == nil else {
            App.shared.snackbar.show(error: GSError.KeyAlreadyImported())
            stop(success: false)
            return
        }

        let success = doImport()
        let key = try? KeyInfo.keys(addresses: [privateKey!.address]).first


        guard success, key != nil else {
            stop(success: false)
            return
        }

        keyInfo = AddressInfo(address: key!.address, name: key!.name)

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
        createPasscodeFlow = CreatePasscodeFlow(navigationController: navigationController, completion: { [unowned self] _ in
            createPasscodeFlow = nil
            didCreatePasscode()
        })
        createPasscodeFlow.start()
    }

    func didCreatePasscode() {
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

