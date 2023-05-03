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
    enum Result {
        //TODO: Remove optional when remove the old security code
        case success(String?)
        case close
    }

    var passcodeCompletion: (_ result: Result) -> Void = { _ in }

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

    fileprivate func didEnterEnoughSymbols(_ text: String) {
        var isCorrect = false
        do {
            if AppConfiguration.FeatureToggles.securityCenter {
                isCorrect = try App.shared.securityCenter.isPasscodeCorrect(plaintextPasscode: text)
            } else {
                isCorrect = try App.shared.auth.isPasscodeCorrect(plaintextPasscode: text)
            }
        } catch {
            showIncorrectPasscodeError()
            return
        }

        if isCorrect {
            passcodeCompletion(.success(text))
        } else {
            wrongAttemptsCount += 1
            if wrongAttemptsCount >= warnAfterWrongAttemptCount {
                showError("\(wrongAttemptsCount) failed password attempts. You can reset password via \"Forgot passcode?\" button below.")
            } else {
                showError("Wrong passcode")
            }
        }
    }

    override func willChangeText(_ text: String) {
        super.willChangeText(text)
        errorLabel.isHidden = true
        if text.count == passcodeLength {
            didEnterEnoughSymbols(text)
        }
    }

    @objc func didTapCloseButton() {
        self.passcodeCompletion(.close)
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
                self.passcodeCompletion(.close)
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
                self.passcodeCompletion(.success(nil))
            case .failure(_):
                self.biometryButton.isHidden = !self.canUseBiometry
            }
        }
    }
}

