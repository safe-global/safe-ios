//
//  ChangePasscodeEnterNewViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class ChangePasscodeEnterNewViewController: PasscodeViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Change Passcode"
        promptLabel.text = "Create a new 6-digit passcode"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        button.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.changePasscodeEnterNew)
    }

    @objc func didTapCloseButton() {
        completion()
    }

    override func willChangeText(_ text: String) {
        super.willChangeText(text)
        if text.count == passcodeLength {
            let vc = RepeatChangedPasscodeViewController(passcode: text, completionHandler: completion)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
