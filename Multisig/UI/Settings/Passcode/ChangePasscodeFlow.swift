//
//  ChangePasscodeFlow.swift
//  Multisig
//
//  Created by Mouaz on 1/30/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

class ChangePasscodeFlow: UIFlow {
    private var factory: ChangePasscodeFlowFactory
    private var oldPasscode: String?
    private var newPasscode: String?

    /// Constructor
    /// - Parameters:
    ///   - factory: screen factory
    ///   - completion: completion block called when flow ends. Argument is `true` when flow successful.
    init(factory: ChangePasscodeFlowFactory = ChangePasscodeFlowFactory(), completion: @escaping (Bool) -> Void) {
        self.factory = factory
        super.init(completion: completion)
    }
    
    override func start() {
        enterOldPasscode()
    }

    func enterOldPasscode() {
        let vc = factory.enterOldPasscode { [unowned self] result in
            switch result {
            case .close:
                stop(success: false)
            case .success(let passcode):
                // Old passcode is required only for security v2 to change the store passcode
                // For the old secuirty either if biometry is enabled then we validate without entering the passcode
                if App.shared.auth.isPasscodeSetAndAvailable && !AppSettings.passcodeOptions.contains(.useBiometry) {
                    guard let passcode = passcode else {
                        App.shared.snackbar.show(error: GSError.FailedToChangePasscode(reason: "Passcode required"))
                        stop(success: false)
                        return
                    }
                }
                oldPasscode = passcode
                enterNewPasscode()
            }
        }

        show(vc)
    }

    func enterNewPasscode() {
        // Old passcode is required only for security v2 to change the store passcode
        // For the old secuirty either if biometry is enabled then we validate without entering the passcode
        if App.shared.auth.isPasscodeSetAndAvailable && !AppSettings.passcodeOptions.contains(.useBiometry) {
            precondition(oldPasscode != nil, "Old passcode should be set before")
        }
        let vc = factory.enterNewPasscode { [unowned self] newPasscode in
            self.newPasscode = newPasscode
            enterRepeatPasscode()
        }

        show(vc)
    }

    func enterRepeatPasscode() {
        precondition(newPasscode != nil, "New passcode should be set before")
        let vc = factory.repeatPasscode(newPasscode!) { [unowned self] in
            stop(success: true)
        }

        show(vc)
    }

    override func stop(success: Bool) {
        if success {
            precondition(newPasscode != nil, "New passcode should be set before")
            do {
                if AppConfiguration.FeatureToggles.securityCenter {
                    precondition(oldPasscode != nil, "Old passcode should be set before")
                    try App.shared.securityCenter.changePasscode(oldPasscode: oldPasscode!, newPasscode: newPasscode!)
                    App.shared.snackbar.show(message: "Passcode changed")
                } else {
                    try App.shared.auth.changePasscode(newPasscodeInPlaintext: newPasscode!)
                    App.shared.snackbar.show(message: "Passcode changed")
                }
            } catch let userCancellationError as GSError.CancelledByUser {
                // do nothing
            } catch {
                App.shared.snackbar.show(error: GSError.FailedToChangePasscode(reason: error.localizedDescription))
            }
        }

        oldPasscode = nil
        newPasscode = nil
        super.stop(success: success)
    }
}

class ChangePasscodeFlowFactory {
    func enterOldPasscode(completion: @escaping ( _ result: EnterPasscodeViewController.Result) -> Void) -> EnterPasscodeViewController {
        let vc = EnterPasscodeViewController()
        vc.passcodeCompletion = completion
        return vc
    }

    func enterNewPasscode(onPasscodeEnter: @escaping (String) -> ()) -> ChangePasscodeEnterNewViewController {
        let vc = ChangePasscodeEnterNewViewController()
        vc.onPasscodeEnter = onPasscodeEnter
        return vc
    }

    func repeatPasscode(_ passcode: String, completion: @escaping () -> ()) -> RepeatChangedPasscodeViewController {
        RepeatChangedPasscodeViewController(passcode: passcode, completionHandler: completion)
    }
}
