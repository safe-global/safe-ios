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
    var skipCompletion: () -> Void = {}
    var passcode: String?

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
        passcode = nil
        super.willChangeText(text)
        guard text.count == passcodeLength else { return }
        passcode = text
        completion()
    }

    override func didTapButton(_ sender: Any) {
        skip()
    }

    func skip() {
        skipCompletion()
        Tracker.trackEvent(.userPasscodeSkipped)
    }

    override func closeModal() {
        skip()
    }
}
