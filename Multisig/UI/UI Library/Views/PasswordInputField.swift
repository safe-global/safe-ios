//
//  PasswordInputField.swift
//  Multisig
//
//  Created by Mouaz on 8/14/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class PasswordInputField: UINibView {
    enum State {
        case empty
        case weak
        case moderate
        case strong
        case matchingEmpty
        case mismatch
        case match
    }

    @IBOutlet weak var textField: UITextField!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var borderView: UIImageView!
    @IBOutlet private weak var stateLabel: UILabel!
    @IBOutlet private weak var stateImageView: UIImageView!
    @IBOutlet private weak var showTextButton: UIButton!

    var onTextChanged: (String) -> ((state: State, message: String?)) = { _ in
        return (.empty, nil)
    }

    var onTextBeginEditing: () -> () = { }

    override func commonInit() {
        super.commonInit()
        set(.empty)
        messageLabel.setStyle(.footnote)
        stateLabel.setStyle(.subheadlineMediumTertiary)
        textField.borderStyle = .none
        textField.setStyle(.bodyPrimary)
    }

    func setPlaceholder(_ text: String?) {
        guard let text = text else {
            textField.attributedPlaceholder = nil
            return
        }
        let attributes = GNOTextStyle.bodyTertiary.attributes
        textField.attributedPlaceholder = NSAttributedString(string: text, attributes: attributes)
    }

    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    func setMessageText(_ value: String?) {
        messageLabel.text = value
    }

    @IBAction private func showTextButtonTouched(_ sender: Any) {
        showTextButton.isSelected.toggle()
        textField.isSecureTextEntry = !showTextButton.isSelected
    }

    private func set(_ state: State, message: String? = nil) {
        var stateText = ""
        var stateStyle = GNOTextStyle.subheadlineMediumTertiary
        var stateImage: String = ""

        switch state {
        case .empty:
            stateText = "Password strength"
            stateStyle = .subheadlineMediumTertiary
            stateImage = "ico-password-empty"
        case .weak:
            stateText = "Weak password"
            stateStyle = .subheadlineMediumError
            stateImage = "ico-password-weak"
        case .moderate:
            stateText = "Moderate password"
            stateStyle = .subheadlineMediumWaring
            stateImage = "ico-password-moderate"
        case .strong:
            stateText = "Strong password"
            stateStyle = .subheadlineMediumSuccess
            stateImage = "ico-password-strong"
        case .matchingEmpty:
            stateText = "Passwords should match"
            stateStyle = .subheadlineMediumTertiary
            stateImage = "ico-password-mismatch-off"
        case .mismatch:
            stateText = "Passwords don’t match"
            stateStyle = .subheadlineMediumError
            stateImage = "ico-password-mismatch"
        case .match:
            stateText = "Passwords match"
            stateStyle = .subheadlineMediumSuccess
            stateImage = "ico-password-match"
        }

        stateLabel.setStyle(stateStyle)
        stateLabel.text = stateText
        setMessageText(message)
        stateImageView.image = UIImage(named: stateImage)
    }

    @IBAction private func textChanged(_ sender: Any) {
        let state = onTextChanged(text!)
        set(state.state, message: state.message)
    }

    @IBAction private func textBeginEditing(_ sender: Any) {
        onTextBeginEditing()
    }
}
