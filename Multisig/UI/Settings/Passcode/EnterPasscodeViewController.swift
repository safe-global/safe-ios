//
//  EnterPasscodeViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class EnterPasscodeViewController: PasscodeViewController {
    var passcodeCompletion: (_ success: Bool, _ reset: Bool) -> Void = { _, _ in }
    var navigationItemTitle = "Enter Passcode"
    var screenTrackingEvent = TrackingEvent.enterPasscode
    var showsCloseButton: Bool = true
    var usesBiometry: Bool = true
    var warnAfterWrongAttemptCount: Int = 5
    var wrongAttemptsCount: Int = 0

    convenience init() {
        self.init(namedClass: PasscodeViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = navigationItemTitle
        promptLabel.text = "Enter your current passcode"
        button.setText("Forgot your passcode?", .plain)
        detailLabel.isHidden = true

        if showsCloseButton {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(didTapCloseButton))
        }

        biometryButton.isHidden = !canUseBiometry
        biometryButton.setImage(App.shared.auth.isFaceID ? UIImage(named: "ic-face-id") : UIImage(named: "ic-touch-id"), for: .normal)
    }

    private var canUseBiometry: Bool {
        usesBiometry && App.shared.auth.isBiometryAuthenticationPossible && AppSettings.passcodeOptions.contains(.useBiometry)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(screenTrackingEvent)
        authenticateWithBiometry()
    }

    override func willChangeText(_ text: String) {
        super.willChangeText(text)
        errorLabel.isHidden = true
        if text.count == passcodeLength {

            var isCorrect = false
            do {
                isCorrect = try App.shared.auth.isPasscodeCorrect(plaintextPasscode: text)
            } catch {
                showGenericError(description: "Failed to check passcode", error: error)
                return
            }

            if isCorrect {
                passcodeCompletion(true, false)
            } else {
                wrongAttemptsCount += 1
                if wrongAttemptsCount >= warnAfterWrongAttemptCount {
                    showError("\(wrongAttemptsCount) failed password attempts. You can reset password via \"Forgot passcode?\" button below.")
                } else {
                    showError("Wrong passcode")
                }
            }
        }
    }

    @objc func didTapCloseButton() {
        passcodeCompletion(false, false)
    }

    override func didTapButton(_ sender: Any) {
        let alertController = UIAlertController(
            title: "Remove all content",
            message: "Disabling the passcode will remove all app content. This cannot be undone. Please type in \"Remove\" to continue.",
            preferredStyle: .alert)

        alertController.addTextField()

        let remove = UIAlertAction(title: "Disable Passcode", style: .destructive) { [unowned self] _ in
            guard alertController.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "Remove" else {
                return
            }
            do {
                // should be before deleting all data
                self.passcodeCompletion(false, true)
                try App.shared.auth.deleteAllData()
            } catch {
                showGenericError(description: "Failed to remove passcode", error: error)
                return
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }

    override func didTapBiometry(_ sender: Any) {
        authenticateWithBiometry()
    }

    private func authenticateWithBiometry() {
        guard canUseBiometry else { return }

        App.shared.auth.authenticateWithBiometrics { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success:
                self.passcodeCompletion(true, false)

            case .failure(_):
                self.biometryButton.isHidden = !self.canUseBiometry
            }
        }
    }
}

