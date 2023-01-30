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
        defer {
            oldPasscode = nil
            newPasscode = nil
        }
        if success {
            precondition(oldPasscode != nil, "Old passcode should be set before")
            precondition(newPasscode != nil, "New passcode should be set before")
            if AppConfiguration.FeatureToggles.securityCenter {
                do {
                    try App.shared.securityCenter.changePasscode(oldPasscode: oldPasscode!, newPasscode: newPasscode!)
                    App.shared.snackbar.show(message: "Passcode changed")
                    super.stop(success: true)
                } catch {
                    App.shared.snackbar.show(message: "Failed to change passcode")
                    super.stop(success: false)
                }
            } else {
                do {
                    try App.shared.auth.changePasscode(newPasscodeInPlaintext: newPasscode!)
                    App.shared.snackbar.show(message: "Passcode changed")
                    super.stop(success: true)
                    return
                } catch {
                    App.shared.snackbar.show(message: "Failed to change passcode")
                }
            }
        } else {
            super.stop(success: false)
        }
    }
}

class ChangePasscodeFlowFactory {
    func enterOldPasscode(completion: @escaping ( _ password: String?) throws -> Void) -> EnterPasscodeViewController {
        let vc = EnterPasscodeViewController()
        vc.onPasscodeEnter = completion

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
