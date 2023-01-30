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
        let vc = factory.enterOldPasscode { [unowned self] password in
                oldPasscode = password
                enterNewPasscode()
        } onError: { [unowned self] error in
            stop(success: false)
        }

        show(vc)
    }

    func enterNewPasscode() {
        precondition(oldPasscode != nil, "Old passcode should be set before")
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
            precondition(oldPasscode != nil, "Old passcode should be set before")
            precondition(newPasscode != nil, "New passcode should be set before")
            do {
                if AppConfiguration.FeatureToggles.securityCenter {
                    try App.shared.securityCenter.changePasscode(oldPasscode: oldPasscode!, newPasscode: newPasscode!)
                    App.shared.snackbar.show(message: "Passcode changed")
                } else {
                    try App.shared.auth.changePasscode(newPasscodeInPlaintext: newPasscode!)
                    App.shared.snackbar.show(message: "Passcode changed")
                }
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
    func enterOldPasscode(completion: @escaping ( _ password: String?) throws -> Void, onError: @escaping (Error) -> ()) -> EnterPasscodeViewController {
        let vc = EnterPasscodeViewController()
        vc.onPasscodeEnter = completion
        vc.onError = onError
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
