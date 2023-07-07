//
//  ChangeLockMethodFlow.swift
//  Multisig
//
//  Created by Mouaz on 1/30/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

class ChangeLockMethodFlow: UIFlow {
    var factory: PasscodeFlowFactory
    private var newLockMethod: LockMethod?
    private var currentLockMethod: LockMethod { AppSettings.securityLockMethod }
    private var userPasscode: String?

    init(newLockMethod: LockMethod, factory: PasscodeFlowFactory = PasscodeFlowFactory(), completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        self.newLockMethod = newLockMethod
        super.init(completion: completion)
    }

    override func start() {
        if currentLockMethod.isPasscodeRequired() {
            // do not request passcode explicitly, it will be requested by security center
            finish(success: true)
        } else if newLockMethod!.isPasscodeRequired() {
            // request new passcode from user with repeating it
            enterNewPasscode()
        }
    }

    func enterNewPasscode() {
        let createVC = factory.create()
        createVC.completion = { [unowned self, unowned createVC] in

            // if entered no passcode, then we finish with failure
            guard let passcode = createVC.passcode else {
                finish(success: false)
                return
            }

            // reset the value to remove from memory
            createVC.passcode = nil

            // if entered passcode, we ask to repeat it
            repeatPasscodeV2(passcode: passcode)
        }
        createVC.skipCompletion = { [unowned self] in

            // if skipped to enter the passcode, then we finish with failure
            finish(success: false)
        }

        show(createVC)
    }

    func repeatPasscodeV2(passcode: String) {
        let repeatVC = factory.repeatPasscode(passcode)
        repeatVC.completion = { [unowned self, unowned repeatVC] in
            // repeated passcode was matching entered passcode, so we finish with success.
            userPasscode = repeatVC.passcode

            // reset from memory
            repeatVC.passcode = nil

            finish(success: true)
        }
        repeatVC.skipCompletion = { [unowned self] in
            // passcode repeat was skipped, so we finish with failure

            // reset passcode from memory
            repeatVC.passcode = nil

            finish(success: false)
        }
        show(repeatVC)
    }

    func finish(success: Bool) {
        if success {
            App.shared.securityCenter.changeLockMethod(oldMethod: currentLockMethod,
                                                       newMethod: newLockMethod!,
                                                       newPasscode: userPasscode) { [unowned self] error in
                if let error = error {
                    if let userCancellation = error as? GSError.CancelledByUser {
                        // do nothing
                    } else {
                        App.shared.snackbar.show(message: "Failed to change lock method: \(error.localizedDescription)")
                    }
                    stop(success: false)
                } else {
                    App.shared.snackbar.show(message: "Lock method changed")
                    stop(success: true)
                }
            }
        } else {
            stop(success: false)
        }
    }

    override func stop(success: Bool) {
        userPasscode = nil
        super.stop(success: success)
    }

}
