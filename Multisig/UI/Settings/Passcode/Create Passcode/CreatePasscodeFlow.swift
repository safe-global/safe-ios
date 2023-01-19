//
//  CreatePasscodeFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

/// Flow for creating a passcode
///
/// Screen sequence:
///
/// 1. Create Passcode
/// 1.1. Nothing, if the passcode already created.
class CreatePasscodeFlow: UIFlow {
    var factory: PasscodeFlowFactory
    private var userPasscode: String!

    init(factory: PasscodeFlowFactory = PasscodeFlowFactory(), completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        super.init(completion: completion)
    }

    override func start() {
        createPasscode()
    }

    func createPasscode() {
        guard !App.shared.auth.isPasscodeSetAndAvailable else {
            stop(success: false)
            return
        }
        let createVC = factory.create()
        createVC.completion = { [unowned self, unowned createVC] in
            guard let passcode = createVC.passcode else {
                stop(success: false)
                return
            }
            // reset to remove from memory
            createVC.passcode = nil
            repeatPasscode(passcode: passcode)
        }
        createVC.skipCompletion = { [unowned self] in
            stop(success: false)
        }

        show(createVC)
    }

    func repeatPasscode(passcode: String) {
        let repeatVC = factory.repeatPasscode(passcode)
        repeatVC.completion = { [unowned self, unowned repeatVC] in
            userPasscode = repeatVC.passcode
            // reset from memory
            repeatVC.passcode = nil
            setupBiometry(presenter: repeatVC)
        }
        repeatVC.skipCompletion = { [unowned self] in
            // reset passcode from memory
            repeatVC.passcode = nil
            stop(success: false)
        }
        show(repeatVC)
    }

    func setupBiometry(presenter: UIViewController) {
        // if device does not support biometrics, finish right away
        guard App.shared.auth.isBiometricsSupported else {
            AppSettings.securityLockMethod = .passcode
            stop(success: true)
            return
        }

        //   if device supports it, ask if to enable biometry
        let biometryAlert = factory.enableBiometryAlert { [unowned self] in
            stop(success: true)
        }

        presenter.present(biometryAlert, animated: true)
    }

    override func stop(success: Bool) {
        defer {
            userPasscode = nil
        }
        if success {
            do {
                try App.shared.auth.createPasscode(plaintextPasscode: userPasscode)
                App.shared.snackbar.show(message: "Passcode created")
                super.stop(success: true)
                return
            } catch {
                App.shared.snackbar.show(message: "Failed to create passcode")
            }
        }
        super.stop(success: false)
    }
}

class PasscodeFlowFactory {
    func create() -> CreatePasscodeViewController {
        let createVC = CreatePasscodeViewController()
        createVC.navigationItem.hidesBackButton = true
        return createVC
    }

    func repeatPasscode(_ passcode: String) -> RepeatPasscodeViewController {
        RepeatPasscodeViewController(passcode: passcode)
    }

    func enableBiometryAlert(completion: @escaping () -> Void) -> UIAlertController {
        ActivateBiometryAlertController(completion: completion)
    }

    func enter(biometry: Bool = true, options: PasscodeOptions = [], reset: @escaping () -> Void = { }, completion: @escaping (_ success: Bool) -> Void) -> EnterPasscodeViewController? {
        guard App.shared.auth.isPasscodeSetAndAvailable && (options.isEmpty || !AppSettings.passcodeOptions.intersection(options).isEmpty) else {
            return nil
        }
        let passcodeVC = EnterPasscodeViewController()
        passcodeVC.usesBiometry = biometry
        passcodeVC.passcodeCompletion = { isSuccess, isReset, _ in
            if isReset {
                reset()
            } else {
                completion(isSuccess)
            }
        }
        return passcodeVC
    }
}
