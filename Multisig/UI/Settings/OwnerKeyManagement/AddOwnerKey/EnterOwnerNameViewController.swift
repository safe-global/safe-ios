//
//  EnterOwnerNameViewController.swift
//  Multisig
//
//  Created by Vitaly on 10.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterOwnerNameViewController: UIViewController {

    var prefix: String?
    var address: Address!
    var name: String?
    var completion: (String) -> Void = { _ in }

    @IBOutlet weak var identiconView: IdenticonView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var textField: GNOTextField!
    @IBOutlet weak var disclaimerLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var buttonBottomConstraint: NSLayoutConstraint!

    private var stepLabel: UILabel!

    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250

    private var keyboardBehavior: KeyboardAvoidingBehavior!

    var stepNumber: Int = 1
    var maxSteps: Int = 3
    
    var trackingEvent: TrackingEvent?
    var trackingParameters: [String: Any]? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: scrollView)

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.calloutTertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        identiconView.set(address: address)
        let prefixString = prefixString()
        addressLabel.attributedText = (prefixString + address.checksummed).highlight(prefix: prefixString.count + 6)

        textField.setPlaceholder("Enter name")
        textField.textField.delegate = self
        textField.textField.becomeFirstResponder()
        if let name = name {
            textField.textField.text = name
        }

        disclaimerLabel.setStyle(.body)

        continueButton.setText("Continue", .filled)

        validateName()

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

    private func validateName() {
        continueButton.isEnabled = false
        guard let text = textField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            self.name = nil
            return
        }
        self.name = text
        continueButton.isEnabled = true
    }

    private func prefixString() -> String {
        (AppSettings.prependingChainPrefixToAddresses && prefix != nil ? "\(prefix!):" : "" )
    }

    @IBAction func didTapContinue(_ sender: Any) {
        completion(name!)
    }
}

extension EnterOwnerNameViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyboardBehavior.activeTextField = textField
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDuration, repeats: false, block: { [weak self] _ in
            self?.validateName()
        })
        return true
    }
}
