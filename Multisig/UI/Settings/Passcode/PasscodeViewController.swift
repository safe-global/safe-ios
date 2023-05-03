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

    var completion: () -> Void = { }

    var keyboardBehavior: KeyboardAvoidingBehavior!

    var passcodeLength: Int {
        symbolsStack.arrangedSubviews.count
    }

    convenience init() {
        self.init(namedClass: PasscodeViewController.self)
    }

    convenience init(_ completionHandler: @escaping () -> Void) {
        self.init(namedClass: PasscodeViewController.self)
        completion = completionHandler
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        headlineLabel.setStyle(.headline)
        promptLabel.setStyle(.headline)
        errorLabel.setStyle(.calloutError)
        detailLabel.setStyle(.callout)
        button.setText("Skip", .plain)
        headlineContainerView.isHidden = hidesHeadline
        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: scrollView)
        keyboardBehavior.hidesKeyboardOnTap = false
        biometryButton.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardBehavior.start()
        reset()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Sometimes the window of the passcode loses the 'key' property.
        // This leads to a case when existing keyboard is shown for a text field in the main window
        // instead of the passcode text field's keyboard in focus.
        // Making the window key window again switches focus to the passcode text field.
        view.window?.makeKey()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
    }

    func append(text: String) {
        self.textFieldDidBeginEditing(textField)
        let shouldChange = self.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: textField.text?.count ?? 0, length: 0),
            replacementString: text)
        guard shouldChange else { return }
        textField.text = (textField.text ?? "") + text
    }

    func reset() {
        textField.text = nil
        updateSymbols(text: "")
        textField.becomeFirstResponder()
        errorLabel.isHidden = true
    }

    @IBAction func didTapButton(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: completion)
        Tracker.trackEvent(.userPasscodeSkipped)
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

    func showIncorrectPasscodeError() {
       showError("Wrong passcode")
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
