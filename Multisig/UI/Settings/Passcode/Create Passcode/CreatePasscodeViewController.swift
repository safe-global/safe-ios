//
//  CreatePasscodeViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class CreatePasscodeViewController: PasscodeViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Create Passcode"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.createPasscode)
    }

    override func willChangeText(_ text: String) {
        super.willChangeText(text)
        guard text.count == passcodeLength else { return }

        // repeat the same passcode
        let repeatVC = RepeatPasscodeViewController(passcode: text)
        navigationController?.pushViewController(repeatVC, animated: true)

        // after that, enable biometry

        repeatVC.completion = { [weak self, weak repeatVC] in
            //  when repeated successfully

            // if device does not support biometrics, finish right away
            guard App.shared.auth.isBiometricsSupported else {
                self?.completion()
                return
            }

            //   if device supports it, ask if to enable biometry
            let shouldEnableVC = UIAlertController(
                title: "Activate Biometry?",
                message: "Would you like to enable login with biometrics?",
                preferredStyle: .alert)

            //      if yes, ask to authenticate with biometry
            shouldEnableVC.addAction(UIAlertAction(title: "Enable", style: .default, handler: { [weak self] _ in

                App.shared.auth.activateBiometrics { _ in
                    // in any resulting case, finish.
                    self?.completion()
                }

            }))

            //      if no, finish right away
            shouldEnableVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
                self?.completion()
            }))

            repeatVC?.present(shouldEnableVC, animated: true, completion: nil)
        }

        repeatVC.skipCompletion = { [weak self] in
            self?.completion()
        }
    }

    override func didTapButton(_ sender: Any) {
        skip()
    }

    func skip() {
        completion()
        Tracker.trackEvent(.userPasscodeSkipped)
    }

    override func closeModal() {
        skip()
    }
}
