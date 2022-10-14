//
//  ClaimedAmountInputCell.swift
//  Multisig
//
//  Created by Moaaz on 6/29/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ClaimedAmountInputCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var redeemWarningLabel: UILabel!
    @IBOutlet private weak var amountTextField: TokenAmountField!
    private var maxButton: UIButton!


    private let fieldDelegate = TokenAmountTextDelegate()

    var didEndValidating: (_ error: String?) -> Void = { _ in } {
        didSet {
            fieldDelegate.didEndValidating = didEndValidating
        }
    }

    var valueRange: Range<Sol.UInt128> {
        get { fieldDelegate.valueRange }
        set { fieldDelegate.valueRange = newValue }
    }

    var value: Sol.UInt128? {
        get { fieldDelegate.inputNumber }
        set { fieldDelegate.set(value: newValue) }
    }

    var isMax: Bool {
        fieldDelegate.isUsingMaxValue
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = "How much do you want to claim?"
        titleLabel.setStyle(.title3)

        descriptionLabel.text = "Select all tokens or custom amount."
        descriptionLabel.setStyle(.body)

        redeemWarningLabel.setStyle(.footnote)

        amountTextField.setToken(image: UIImage(named: "ico-safe-token-logo-circle"))

        maxButton = UIButton(type: .custom)
        maxButton.setText("Max", .primary)
        maxButton.addTarget(self, action: #selector(maxButtonTouched(_:)), for: .touchUpInside)

        amountTextField.amountTextField.rightView = maxButton
        amountTextField.amountTextField.rightViewMode = .always

        fieldDelegate.textField = amountTextField
    }

    @objc func maxButtonTouched(_ sender: Any) {
        Tracker.trackEvent(.userClaimFormMax)
        fieldDelegate.setMaxValue()
    }

    func set(redeemDeadlineLabelVisible: Bool) {
        redeemWarningLabel.isHidden = !redeemDeadlineLabelVisible
    }
}

import Solidity
import SwiftCryptoTokenFormatter

class TokenAmountTextDelegate: NSObject, UITextFieldDelegate {

    private let validationDelayInSeconds: TimeInterval = 0.25
    private var timer: Timer!
    let formatter = TokenFormatter()

    weak var textField: TokenAmountField! {
        didSet {
            textField?.delegate = self
        }
    }
    var valueRange: Range<Sol.UInt128> = (0..<1)

    var isValid: Bool {
        validationError == nil
    }

    var validationError: String? {
        didSet {
            textField.showError(message: validationError)
        }
    }

    var didEndValidating: (_ error: String?) -> Void = { _ in }

    var inputNumber: Sol.UInt128? {
        if let decimal = formatter.number(from: textField.balance, precision: 18),
           decimal.value >= 0 && decimal.value <= Sol.UInt128.max {
            let value = Sol.UInt128(big: UInt256(decimal.value))
            return valueRange.contains(value) ? value : nil
        }
        return nil
    }

    var isUsingMaxValue: Bool = false

    func formatted(_ value: Sol.UInt128, literal: Bool = true) -> String {
        let decimal = BigDecimal(Int256(value.big()), 18)
        let result: String
        if literal {
            result = formatter.string(from: decimal, thousandSeparator: "", shortFormat: true)
        } else {
            result = formatter.string(from: decimal)
        }
        return result
    }

    func set(value: Sol.UInt128?) {
        if let value = value {
            textField.balance = formatted(value)
        } else {
            textField.balance = ""
        }

        validate()
    }

    func setMaxValue() {
        let maxValue = valueRange.upperBound - 1
        isUsingMaxValue = true
        textField.balance = formatted(maxValue)
        validate()
    }

    // called after a delay on every key stroke and also after text finished editing
    func validate() {
        defer {
            didEndValidating(validationError)
        }
        let string = textField.balance.trimmingCharacters(in: .whitespacesAndNewlines)
        validationError = nil

        // cannot be empty
        if string.isEmpty {
            validationError = "Please enter amount"
            return
        }

        // must be a number
        guard let decimal = formatter.number(from: string, precision: 18) else {
            validationError = "Please enter a positive number (max 18 digits after decimal point)"
            return
        }

        // must be within range of UInt128
        guard decimal.value >= 0 && decimal.value <= Sol.UInt128.max else {
            validationError = "Value is too big. Please enter a smaller number."
            return
        }
        let number = Sol.UInt128(big: UInt256(decimal.value))

        // must be within value range
        guard valueRange.contains(number) else {
            let lowBound = formatted(valueRange.lowerBound, literal: false)
            let highBound = formatted(valueRange.upperBound, literal: false)
            validationError = "Please enter value in range from \(lowBound) to \(highBound)"
            return
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        defer {
            userDidChangeText()
        }
        let oldText = (textField.text ?? "") as NSString
        let newText = oldText.replacingCharacters(in: range, with: string)

        if newText.isEmpty {
            return true
        }
        var correctedText = newText

        // replace any of the different 'dot' characters coming from keyboard with a simple '.'
        for dotChar in ".,٫" {
            correctedText = correctedText.replacingOccurrences(of: String(dotChar), with: ".")
        }

        if correctedText.hasPrefix(".") {
            correctedText = "0" + correctedText
        }

        let pattern = "^\\d+\\.?\\d*$"
        let isPartialNumber = correctedText.matches(pattern: pattern)
        var shouldReplaceText = isPartialNumber

        // remove leading zeroes
        while correctedText.matches(pattern: "^0\\d+") {
            correctedText.removeFirst()
        }

        if correctedText != newText {
            textField.text = correctedText
            shouldReplaceText = false
        }

        return shouldReplaceText
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.textField.updateBorder()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.textField.updateBorder()

        defer {
            userDidChangeText()
        }

        guard var correctedText = textField.text, !correctedText.isEmpty else {
            return
        }

        // remove trailing zeroes
        while correctedText.matches(pattern: "\\.\\d*0+$") {
            correctedText.removeLast()
        }

        // remove trailing dot
        if correctedText.matches(pattern: "^\\d+\\.$") {
            correctedText.removeLast()
        }

        textField.text = correctedText
    }

    private func userDidChangeText() {
        isUsingMaxValue = false

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: validationDelayInSeconds, repeats: false) { [weak self] _ in
            self?.validate()
        }
    }
}
