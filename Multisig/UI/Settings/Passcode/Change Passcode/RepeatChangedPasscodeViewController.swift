//
//  RepeatChangedPasscodeViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class RepeatChangedPasscodeViewController: PasscodeViewController {
    var passcode: String!

    convenience init(passcode: String, completionHandler: @escaping () -> Void) {
        self.init(namedClass: PasscodeViewController.self)
        self.passcode = passcode
        completion = completionHandler
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Change Passcode"
        promptLabel.text = "Repeat the 6-digit passcode"
        button.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.changePasscodeRepeat)
    }

    override func willChangeText(_ text: String) {
        super.willChangeText(text)
        errorLabel.isHidden = true
        if text == passcode {
            do {
                try App.shared.auth.changePasscode(newPasscodeInPlaintext: text)
                App.shared.snackbar.show(message: "Passcode changed")
                navigationController?.dismiss(animated: true) { [unowned self] in
                    self.completion()
                }
            } catch {
                showGenericError(description: "Failed to change passcode", error: error)
            }
        } else if text.count == passcodeLength {
            showError("Passcodes don't match")
        }
    }
}

