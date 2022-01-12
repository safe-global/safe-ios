//
//  LabeledTextField.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class LabeledTextField: UINibView {

    @IBOutlet weak var infoLabel: InfoLabel!
    @IBOutlet weak var gnoTextField: GNOTextField!
    @IBOutlet weak var captionLabel: UILabel!

    static let textFieldHeight: CGFloat = 40

    private var textFieldHeightConstraint: NSLayoutConstraint!

    var validator: TextValidator?
    weak var fieldDelegate: FieldDelegate?

    override func commonInit() {
        super.commonInit()
        textFieldHeightConstraint = gnoTextField.textField.heightAnchor.constraint(equalToConstant: Self.textFieldHeight)
        textFieldHeightConstraint.isActive = true
        setCaption(nil)
        gnoTextField.textField.delegate = self

        // pass from outside?
        gnoTextField.textField.keyboardType = .numberPad // for integers?
    }

    func setCaption(_ value: String?, style: GNOTextStyle = .caption1.weight(.medium)) {
        captionLabel.text = value
        captionLabel.setStyle(style)
        captionLabel.isHidden = value == nil
    }
}

extension LabeledTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        fieldDelegate?.textFieldFocused(textField)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let validator = validator else { return true }
        let currentText = textField.text as NSString?
        let partialText = currentText?.replacingCharacters(in: range, with: string)

        do {
            setError(nil)
            let validatedText = try validator.validate(partialValue: partialText)
            textField.text = validatedText
        } catch {
            setError(error)
        }

        return false
    }

    func setError(_ error: Error?) {
        let oldValue = gnoTextField.errorText
        gnoTextField.setError(error)
        let newValue = gnoTextField.errorText
        if oldValue != newValue {
            fieldDelegate?.layoutNeeded()
        }
    }
}

protocol TextValidator {
    func validate(partialValue: String?) throws -> String?
}

class IntegerTextValidator: TextValidator {

    /// Validates and corrects the value
    /// - Parameter partialValue: partial user input value
    /// - Returns: corrected value
    func validate(partialValue: String?) throws -> String? {
        guard let partialValue = partialValue, !partialValue.isEmpty else {
            return partialValue
        }

        let isDigits = partialValue.numberOfMatches(pattern: "^\\d+$") == 1

        guard isDigits else {
            throw TextValidationError(code: -1, message: "Entered value is not a digit")
        }

        let droppedLeadingZeroes = partialValue.drop(while: { $0 == "0" })

        let result = droppedLeadingZeroes.isEmpty ? "0" : droppedLeadingZeroes

        return String(result)
    }
}


struct TextValidationError: LocalizedError {
    let code: Int
    let message: String

    var errorDescription: String? {
        message + " (Error \(code))"
    }
}

extension String {
    // pattern must be a valid regular expression or this will crash
    func numberOfMatches(pattern: String) -> Int {
        do {
            let regexp = try NSRegularExpression(pattern: pattern, options: [])
            let matchCount = regexp.numberOfMatches(in: self, options: [], range: NSRange(location: 0, length: count))
            return matchCount
        } catch {
            preconditionFailure("Invalid regexp pattern: \(pattern): \(error)")
        }
    }
}
