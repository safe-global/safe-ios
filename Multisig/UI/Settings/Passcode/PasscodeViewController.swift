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
        headlineContainerView.isHidden = true
        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: scrollView)
        keyboardBehavior.hidesKeyboardOnTap = false
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
}


class CreatePasscodeViewController: PasscodeViewController {
    convenience init() {
        self.init(namedClass: PasscodeViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Create Passcode"
        headlineContainerView.isHidden = false
    }

    override func willChangeText(_ text: String) {
        super.willChangeText(text)
        if text.count == passcodeLength {
            let vc = RepeatPasscodeViewController(passcode: text)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

class RepeatPasscodeViewController: PasscodeViewController {

    var passcode: String!

    convenience init(passcode: String) {
        self.init(namedClass: PasscodeViewController.self)
        self.passcode = passcode
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Create Passcode"
        promptLabel.text = "Repeat the 6-digit passcode"
    }

    override func willChangeText(_ text: String) {
        super.willChangeText(text)
        errorLabel.isHidden = true
        if text == passcode {
            do {
                try App.shared.auth.createPasscode(plaintextPasscode: text)
                App.shared.snackbar.show(message: "Passcode created")
                navigationController?.dismiss(animated: true, completion: nil)
            } catch {
                let uiError = GSError.error(
                    description: "Failed to create passcode",
                    error: GSError.CreatePasscodeError(reason: error.localizedDescription))
                errorLabel.text = uiError.localizedDescription
                errorLabel.isHidden = false
            }
        } else if text.count == passcodeLength {
            errorLabel.text = "Passcodes don't match"
            errorLabel.isHidden = false
        }
    }
}
