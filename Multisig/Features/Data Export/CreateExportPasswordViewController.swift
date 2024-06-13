//
//  CreateExportPasswordViewController.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 03.06.24.
//  Copyright © 2024 Core Contributors GmbH. All rights reserved.
//


import UIKit

class CreateExportPasswordViewController: UIViewController {

    var prompt: String = ""
    var placeholder: String = ""
    var plainTextPassword: String?
    var passwordMeterEnabled: Bool = false
    var completion: (String) -> Void = { _ in }
    var validateValue: (String) -> Error? = { _ in nil }

    @IBOutlet weak var textField: GNOTextField!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var buttonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var passwordMeter: UIProgressView!

    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250
    private var isValid: Bool = false

    private var keyboardBehavior: KeyboardAvoidingBehavior!

    var trackingEvent: TrackingEvent?
    var trackingParameters: [String: Any]? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: scrollView)

        textField.setPlaceholder(placeholder)
        textField.textField.isSecureTextEntry = true
        textField.textField.delegate = self
        textField.textField.clearButtonMode = .always

        if let value = plainTextPassword {
            textField.textField.text = value
        }

        descriptionLabel.text = prompt
        descriptionLabel.setStyle(.body)

        continueButton.setText("Continue", .filled)
        
        passwordMeter.isHidden = !passwordMeterEnabled

        validateText()

        NotificationCenter.default.addObserver(self,
                                       selector: #selector(willShowKeyboard(_:)),
                                       name: UIResponder.keyboardWillShowNotification,
                                       object: nil)
        NotificationCenter.default.addObserver(self,
                                       selector: #selector(willHideKeyboard(_:)),
                                       name: UIResponder.keyboardWillHideNotification,
                                       object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardBehavior.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let trackingEvent = trackingEvent {
            Tracker.trackEvent(trackingEvent, parameters: trackingParameters)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
    }

    @objc func willShowKeyboard(_ notification: NSNotification) {
        guard
            let frameEnd = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber
        else {
            return
        }

        UIView.animate(withDuration: animationDuration.doubleValue) { [weak self] in
            self?.buttonBottomConstraint?.constant = 16 + frameEnd.cgRectValue.height
            self?.view?.layoutIfNeeded()
        }
    }

    @objc func willHideKeyboard(_ notification: NSNotification) {
        guard
            let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber
        else {
            return
        }
        UIView.animate(withDuration: animationDuration.doubleValue) { [weak self] in
            self?.buttonBottomConstraint?.constant = 16
            self?.view?.layoutIfNeeded()
        }
    }

    func passwordScore(_ text: String) -> Double {
        // We define score P as:
        // P[ L >= 8 ] = 8 * L * (1 + 0.1 * N + 0.1 * S + 0.1 * C)
        // P[ L < 8 ] = 8 * L
        //   where L = length of the password text string
        //      N = 1 if password contains numbers, 0 otherwise
        //      S = 1 if password contains symbols, 0 otherwise
        //      C = 1 if password contains capital letters, 0 otherwise
        // Maximum P value equals 100, i.e.:
        // P = min(P, 100)
        let L = Double(text.count)
        let N = text.rangeOfCharacter(from: .decimalDigits) == nil ? 0 : 1.0
        let S = text.rangeOfCharacter(from: .symbols) == nil ? 0 : 1.0
        let C = text.rangeOfCharacter(from: .capitalizedLetters) == nil ? 0 : 1.0
        let P = min(100, (L < 8) ? (8 * L) : (8 * L * (1 + 0.1 * N + 0.1 * S + 0.1 * C)) )
        return P
    }

    fileprivate func resetText() {
        isValid = false
        continueButton.isEnabled = false
        textField.setError(nil)
        passwordMeter.progress = 0
    }
    
    private func validateText() {
        resetText()
        guard let text = textField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            self.plainTextPassword = nil
            return
        }
        passwordMeter.progress = Float(passwordScore(text) / 100)
        if let error = validateValue(text) {
            textField.setError(error)
            return
        }
        self.plainTextPassword = text
        continueButton.isEnabled = true
        isValid = true
    }

    @IBAction func didTapContinue(_ sender: Any) {
        completion(plainTextPassword!)
    }
}

extension CreateExportPasswordViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyboardBehavior.activeTextField = textField
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.resetText()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDuration, repeats: false, block: { [weak self] _ in
            self?.validateText()
        })
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if isValid {
            didTapContinue(textField)
            textField.resignFirstResponder()
        }
        return true
    }
}
