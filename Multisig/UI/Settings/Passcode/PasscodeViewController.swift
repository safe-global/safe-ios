//
//  PasscodeViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 2/22/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class PasscodeViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var headlineContainerView: UIView!
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var symbolsStack: UIStackView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var biometryButton: UIButton!
    @IBOutlet weak var symbolsButton: UIButton!

    var hidesHeadline = true

    var keyboardBehavior: KeyboardAvoidingBehavior!

    var passcodeLength: Int {
        symbolsStack.arrangedSubviews.count
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        headlineLabel.setStyle(.headline)
        promptLabel.setStyle(.primary)
        errorLabel.setStyle(.error)
        detailLabel.setStyle(.secondary)
        button.setText("Skip", .plain)
        headlineContainerView.isHidden = hidesHeadline
        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: scrollView)
        keyboardBehavior.hidesKeyboardOnTap = false
        biometryButton.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardBehavior.start()
        textField.text = nil
        updateSymbols(text: "")
        textField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
    }

    @IBAction func didTapButton(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
        trackEvent(.userPasscodeSkipped)
    }

    @IBAction func didTapBiometry(_ sender: Any) {
        // to override in a subclass
    }

    @IBAction func didTapSymbolsButton(_ sender: Any) {
        textField.becomeFirstResponder()
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyboardBehavior.activeTextField = textField
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        guard text.count <= passcodeLength &&
                (text.isEmpty ||
                    // text is only digits
                    text.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) })) else {
            return false
        }
        willChangeText(text)
        return true
    }

    func willChangeText(_ text: String) {
        updateSymbols(text: text)
    }

    func updateSymbols(text: String) {
        // update symbols
        let symbols = symbolsStack.arrangedSubviews as! [UIImageView]
        for (index, imageView) in symbols.enumerated() {
            imageView.image = UIImage(systemName: index < text.count ? "circle.fill" : "circle")
        }
    }

    func showGenericError(description: String, error: Error) {
        let uiError = GSError.error(
            description: description,
            error: GSError.GenericPasscodeError(reason: error.localizedDescription))
        errorLabel.text = uiError.localizedDescription
        errorLabel.isHidden = false
    }

    func showError(_ text: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let `self` = self else { return }
            self.errorLabel.text = text
            self.errorLabel.isHidden = false
            self.textField.text = ""
            self.updateSymbols(text: "")
        }
    }
}


class CreatePasscodeViewController: PasscodeViewController {
    private var completion: () -> Void = {}

    convenience init() {
        self.init(namedClass: PasscodeViewController.self)
    }

    convenience init(_ completionHandler: @escaping () -> Void) {
        self.init(namedClass: PasscodeViewController.self)
        completion = completionHandler
    }

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
        trackEvent(.createPasscode)
    }

    override func willChangeText(_ text: String) {
        super.willChangeText(text)
        if text.count == passcodeLength {
            let vc = RepeatPasscodeViewController(passcode: text) { [unowned self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    if let activated = try? App.shared.auth.activateBiometry(), activated {
                        AppSettings.passcodeOptions.insert(.useBiometry)
                        NotificationCenter.default.post(name: .biometricsActivated, object: nil)
                        App.shared.snackbar.show(message: "Biometrics activated.")
                    }
                }
                self.completion()
            }
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

class RepeatPasscodeViewController: PasscodeViewController {
    var passcode: String!
    private var completion: () -> Void = {}

    convenience init(passcode: String, completionHandler: @escaping () -> Void) {
        self.init(namedClass: PasscodeViewController.self)
        self.passcode = passcode
        completion = completionHandler
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Create Passcode"
        promptLabel.text = "Repeat the 6-digit passcode"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.repeatPasscode)
    }

    override func willChangeText(_ text: String) {
        super.willChangeText(text)
        errorLabel.isHidden = true
        if text == passcode {
            do {
                try App.shared.auth.createPasscode(plaintextPasscode: text)
                App.shared.snackbar.show(message: "Passcode created")
                navigationController?.dismiss(animated: true, completion: nil)
                completion()
            } catch {
                showGenericError(description: "Failed to create passcode", error: error)
            }
        } else if text.count == passcodeLength {
            showError("Passcodes don't match")
        }
    }
}

class EnterPasscodeViewController: PasscodeViewController {
    var completion: (Bool) -> Void = { _ in }
    var navigationItemTitle = "Enter Passcode"
    var screenTrackingEvent = TrackingEvent.enterPasscode
    var showsCloseButton: Bool = true
    var usesBiometry: Bool = true

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
        usesBiometry && App.shared.auth.isBiometryPossible && AppSettings.passcodeOptions.contains(.useBiometry)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(screenTrackingEvent)
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
                completion(true)
            } else {
                showError("Wrong passcode")
            }
        }
    }

    @objc func didTapCloseButton() {
        completion(false)
    }

    override func didTapButton(_ sender: Any) {
        let alertController = UIAlertController(
            title: nil,
            message: "You can disable your passcode. This will remove all data from the app.",
            preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: "Disable Passcode", style: .destructive) { [unowned self] _ in
            do {
                try App.shared.auth.deleteAllData()
                completion(false)
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
        let success = App.shared.auth.authenticateWithBiometry()
        if success {
            completion(true)
        }
    }
}

class ChangePasscodeEnterNewViewController: PasscodeViewController {
    var completion: () -> Void = { }

    convenience init(_ completionHandler: @escaping () -> Void = { }) {
        self.init(namedClass: PasscodeViewController.self)
        completion = completionHandler
    }

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
        trackEvent(.changePasscodeEnterNew)
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

class RepeatChangedPasscodeViewController: PasscodeViewController {
    var passcode: String!
    private var completion: () -> Void = {}

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
        trackEvent(.changePasscodeRepeat)
    }

    override func willChangeText(_ text: String) {
        super.willChangeText(text)
        errorLabel.isHidden = true
        if text == passcode {
            do {
                try App.shared.auth.changePasscode(newPasscodeInPlaintext: text)
                App.shared.snackbar.show(message: "Passcode changed")
                navigationController?.dismiss(animated: true, completion: nil)
                completion()
            } catch {
                showGenericError(description: "Failed to change passcode", error: error)
            }
        } else if text.count == passcodeLength {
            showError("Passcodes don't match")
        }
    }
}
