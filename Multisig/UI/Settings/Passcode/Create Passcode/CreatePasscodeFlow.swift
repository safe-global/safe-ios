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
    private var userPasscode: String?

    init(factory: PasscodeFlowFactory = PasscodeFlowFactory(), completion: @escaping (_ success: Bool) -> Void) {
        self.factory = factory
        super.init(completion: completion)
    }

    override func start() {
        if AppConfiguration.FeatureToggles.securityCenter {
            startV2()
        } else {
            createPasscode()
        }
    }

    func startV2() {
        userPasscode = nil

        if App.shared.securityCenter.securityLockEnabled {
            stop(success: false)
            return
        }

        createPasscodeV2()
        setupBiometryV2()
    }

    func setupBiometryV2() {
        AppSettings.securityLockMethod = .passcode

        // if device does not support biometrics, finish right away
        guard App.shared.auth.isBiometricsSupported else {
            createPasscodeV2()
            return
        }

        //   if device supports it, ask if to enable biometry
        let biometryAlert = factory.enableBiometryAlert { [unowned self] in
            // if user enabled biometry, we finish
            if AppSettings.securityLockMethod == .userPresence {
                stop(success: true)
            }
            // otherwise, alert is dismissed to show the passcode screen.
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [unowned self] in
            self.navigationController.present(biometryAlert, animated: true)
        }
    }

    func createPasscodeV2() {
        let createVC = factory.create()
        createVC.completion = { [unowned self, unowned createVC] in

            // if entered no passcode, then we finish with failure
            guard let passcode = createVC.passcode else {
                stop(success: false)
                return
            }

            // reset the value to remove from memory
            createVC.passcode = nil

            // if entered passcode, we ask to repeat it
            repeatPasscodeV2(passcode: passcode)
        }
        createVC.skipCompletion = { [unowned self] in

            // if skipped to enter the passcode, then we finish with failure
            stop(success: false)
        }

        show(createVC)
    }

    // if v2 failed / skipped, the options & lock method needs to be reset

    func repeatPasscodeV2(passcode: String) {
        let repeatVC = factory.repeatPasscode(passcode)
        repeatVC.completion = { [weak self, weak repeatVC] in
            // repeated passcode was matching entered passcode, so we finish with success.
            self?.userPasscode = repeatVC?.passcode

            // reset from memory
            repeatVC?.passcode = nil

            self?.stop(success: true)
        }
        repeatVC.skipCompletion = { [weak self, weak repeatVC] in
            // passcode repeat was skipped, so we finish with failure

            // reset passcode from memory
            repeatVC?.passcode = nil

            self?.stop(success: false)
        }

        show(repeatVC)
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
        if AppConfiguration.FeatureToggles.securityCenter {
            if success {
                // we have successfully received input from user: biometry or passcode.
                // we have set the lock method already
                do {
                    try App.shared.securityCenter.enableSecurityLock(passcode: userPasscode)
                    App.shared.snackbar.show(message: "Passcode created")
                    super.stop(success: true)
                } catch {

                    App.shared.snackbar.show(message: "Failed to create passcode [](\(error.localizedDescription))")
                    super.stop(success: false)
                }
            } else {
                super.stop(success: false)
            }
        } else {
            if success {
                do {
                    try App.shared.auth.createPasscode(plaintextPasscode: userPasscode!)
                    App.shared.snackbar.show(message: "Passcode created")
                    super.stop(success: true)
                    return
                } catch {
                    App.shared.snackbar.show(message: "Failed to create passcode (\(error.localizedDescription))")
                }
            }
            super.stop(success: false)
        }
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

    func enter(biometry: Bool = true, options: PasscodeOptions = [], completion: @escaping (_ result: EnterPasscodeViewController.Result) -> Void) -> EnterPasscodeViewController? {
        guard App.shared.auth.isPasscodeSetAndAvailable && (options.isEmpty || !AppSettings.passcodeOptions.intersection(options).isEmpty) else {
            return nil
        }
        let passcodeVC = EnterPasscodeViewController()
        passcodeVC.usesBiometry = biometry
        passcodeVC.passcodeCompletion = completion
        return passcodeVC
    }
}
