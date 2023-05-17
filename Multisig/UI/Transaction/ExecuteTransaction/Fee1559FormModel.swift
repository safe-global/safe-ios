//
//  Fee1559FormModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Solidity
import Ethereum
import UIKit

class Fee1559FormModel: FormModel {
    weak var delegate: FieldDelegate? = nil
    var isValid: Bool?

    var nonce: Sol.UInt64?
    var minimalNonce: Sol.UInt64!
    var gas: Sol.UInt64?
    var maxFeePerGasInWei: Sol.UInt256?
    var maxPriorityFeePerGasInWei: Sol.UInt256?

    let gigaweiDecimals = 9

    var totalFeeInWei: Sol.UInt256? {
        guard let gas = gas,
              // maxFee = maxPriorityFee + baseFee (implied)
                let maxFeePerGas = maxFeePerGasInWei,
                let maxPriorityFee = maxPriorityFeePerGasInWei,
              // maxFeePerGas must include priority fee
                maxFeePerGas >= maxPriorityFee
        else {
            return nil
        }
        let (partialResult, overflow) = Sol.UInt256(gas).multipliedReportingOverflow(by: maxFeePerGas)
        if overflow { return nil}
        return partialResult
    }

    var nativeCurrency: ChainToken

    var gasField: LabeledTextField!
    var nonceField: LabeledTextField!
    var maxFeePerGasField: LabeledTextField!
    var maxPriorityFeeField: LabeledTextField!

    var helpField: HyperlinkButtonView!

    var nonceText: String? {
        guard let value = nonce else { return nil }
        let result = String(value, radix: 10)
        return result
    }

    var gasText: String? {
        guard let value = gas else { return nil }
        let result = String(value, radix: 10)
        return result
    }

    var maxFeePerGasInGigaweiText: String? {
        guard let maxFeePerGasInWei = maxFeePerGasInWei else {
            return nil
        }
        let amount = Eth.TokenAmount(value: maxFeePerGasInWei, decimals: gigaweiDecimals)
        let result = amount.description
        return result
    }

    var maxPriorityFeePerGasInGigaweiText: String? {
        guard let maxPriorityFeePerGasInWei = maxPriorityFeePerGasInWei else {
            return nil
        }
        let amount = Eth.TokenAmount(value: maxPriorityFeePerGasInWei, decimals: gigaweiDecimals)
        let result = amount.description
        return result
    }

    var totalFeeInNativeCoinText: String? {
        guard let totalFee = totalFeeInWei else {
            return "Total estimated fee: n/a"
        }
        let amount = Eth.TokenAmount(
            value: totalFee,
            decimals: Int(nativeCurrency.decimals),
            symbol: nativeCurrency.symbol ?? "")
        let result = "Total estimated fee: \(amount)"
        return result
    }

    init(nonce: Sol.UInt64?, minimalNonce: Sol.UInt64 = 0, gas: Sol.UInt64?, maxFeePerGasInWei: Sol.UInt256?, maxPriorityFeePerGasInWei: Sol.UInt256?, nativeCurrency: ChainToken) {
        self.nonce = nonce
        self.minimalNonce = minimalNonce
        self.gas = gas
        self.maxFeePerGasInWei = maxFeePerGasInWei
        self.maxPriorityFeePerGasInWei = maxPriorityFeePerGasInWei
        self.nativeCurrency = nativeCurrency
    }

    func fields() -> [UIView] {
        nonceField = LabeledTextField()
        nonceField.infoLabel.setText(
            "Nonce",
            description: "Transaction count of the execution account",
            style: .headline
        )
        nonceField.gnoTextField.setPlaceholder("Nonce")
        nonceField.gnoTextField.text = nonceText
        nonceField.gnoTextField.textField.keyboardType = .numberPad
        nonceField.validator = IntegerTextValidator()
        nonceField.fieldDelegate = delegate

        gasField = LabeledTextField()
        gasField.infoLabel.setText(
            "Gas limit",
            description: "Maximum gas that this transaction can spend. Unused gas will be refunded",
            style: .headline
        )
        gasField.gnoTextField.setPlaceholder("Gas limit")
        gasField.gnoTextField.text = gasText
        gasField.gnoTextField.textField.keyboardType = .numberPad
        gasField.validator = IntegerTextValidator()
        gasField.fieldDelegate = delegate

        maxPriorityFeeField = LabeledTextField()
        maxPriorityFeeField.infoLabel.setText(
            "Max priority fee per gas (GWEI)",
            description: "Maximum tip to miner per 1 gas in Gwei price units",
            style: .headline
        )
        maxPriorityFeeField.gnoTextField.setPlaceholder("Max priority fee per gas (GWEI)")
        maxPriorityFeeField.gnoTextField.text = maxPriorityFeePerGasInGigaweiText
        maxPriorityFeeField.gnoTextField.textField.keyboardType = .decimalPad
        maxPriorityFeeField.validator = DecimalTextValidator()
        maxPriorityFeeField.fieldDelegate = delegate

        maxFeePerGasField = LabeledTextField()
        maxFeePerGasField.infoLabel.setText(
            "Max fee per gas (GWEI)",
            description: "Maximum limit paid per 1 gas in Gwei price units",
            style: .headline
        )
        maxFeePerGasField.gnoTextField.setPlaceholder("Max fee per gas (GWEI)")
        maxFeePerGasField.gnoTextField.text = maxFeePerGasInGigaweiText
        maxFeePerGasField.gnoTextField.textField.keyboardType = .decimalPad
        maxFeePerGasField.validator = DecimalTextValidator()
        maxFeePerGasField.fieldDelegate = delegate

        maxFeePerGasField.setCaption(totalFeeInNativeCoinText)

        helpField = HyperlinkButtonView()
        helpField.setText("How do I configure these details manually?")
        helpField.url = App.configuration.help.advancedTxParamsURL

        return [nonceField,
                gasField,
                maxPriorityFeeField,
                maxFeePerGasField,
                helpField]
    }

    func validate() {
        let allValidations = [
            validateNonce(),
            validateGas(),
            validateMaxPriorityFee(),
            validateMaxFeePerGas(),
            validateTotalFee()
        ]
        let allFieldsAreValid = allValidations.reduce(true) { partialResult, value in
            partialResult && value
        }
        self.isValid = allFieldsAreValid

        maxFeePerGasField.setCaption(totalFeeInNativeCoinText)

        delegate?.layoutNeeded()
    }

    func validateGas() -> Bool {
        gasField.gnoTextField.setErrorText(nil)

        guard let gasText = gasField.text, !gasText.isEmpty else {
            gasField.gnoTextField.setErrorText("This value is required")
            return false
        }

        guard let value = Sol.UInt64(gasText, radix: 10) else {
            gasField.gnoTextField.setErrorText("Value is not a valid number")
            return false
        }

        gas = value
        return true
    }

    func validateNonce() -> Bool {
        nonceField.gnoTextField.setErrorText(nil)

        guard let text = nonceField.text, !text.isEmpty else {
            nonceField.gnoTextField.setErrorText("This value is required")
            return false
        }

        guard let value = Sol.UInt64(text, radix: 10) else {
            nonceField.gnoTextField.setErrorText("Value is not a valid number")
            return false
        }
        
        if value < minimalNonce {
            nonceField.gnoTextField.setErrorText("Transaction with this nonce is already executed")
            return false
        }

        nonce = value
        return true
    }

    func validateMaxFeePerGas() -> Bool {
        maxFeePerGasField.gnoTextField.setErrorText(nil)

        guard let text = maxFeePerGasField.text, !text.isEmpty else {
            maxFeePerGasField.gnoTextField.setErrorText("This value is required")
            return false
        }

        guard let amount = Eth.TokenAmount<Sol.UInt256>(text, radix: 10, decimals: gigaweiDecimals) else {
            maxFeePerGasField.gnoTextField.setErrorText("Value is not a valid number")
            return false
        }
        
        if amount.value == 0  {
            maxFeePerGasField.gnoTextField.setErrorText("Value should be greater than 0")
            return false
        }

        guard let maxPriorityFeeAmount = maxPriorityFeeAmount, amount.value >= maxPriorityFeeAmount.value else {
            maxFeePerGasField.gnoTextField.setErrorText("Max fee must be greater or equal than max priority fee")
            return false
        }

        maxFeePerGasInWei = amount.value
        return true
    }

    func validateMaxPriorityFee() -> Bool {
        maxPriorityFeeField.gnoTextField.setErrorText(nil)

        guard let text = maxPriorityFeeField.text, !text.isEmpty else {
            maxPriorityFeeField.gnoTextField.setErrorText("This value is required")
            return false
        }

        guard let amount = Eth.TokenAmount<Sol.UInt256>(text, radix: 10, decimals: gigaweiDecimals) else {
            maxPriorityFeeField.gnoTextField.setErrorText("Value is not a valid number")
            return false
        }
        
        if amount.value == 0  {
            maxPriorityFeeField.gnoTextField.setErrorText("Value should be greater than 0")
            return false
        }

        guard let maxFeeAmount = maxFeePerGasAmount, amount.value <= maxFeeAmount.value else {
            maxPriorityFeeField.gnoTextField.setErrorText("Max priority fee must be less than or equal to max fee")
            return false
        }

        maxPriorityFeePerGasInWei = amount.value
        return true
    }

    var maxFeePerGasAmount: Eth.TokenAmount<Sol.UInt256>? {
        maxFeePerGasField.text.flatMap {
            Eth.TokenAmount($0, radix: 10, decimals: gigaweiDecimals)
        }
    }

    var maxPriorityFeeAmount: Eth.TokenAmount<Sol.UInt256>? {
        maxPriorityFeeField.text.flatMap {
            Eth.TokenAmount($0, radix: 10, decimals: gigaweiDecimals)
        }
    }

    func validateTotalFee() -> Bool {
        guard totalFeeInWei != nil else {
            gasField.gnoTextField.setErrorText("Total fee is too high")
            maxFeePerGasField.gnoTextField.setErrorText("Total fee is too high ")
            return false
        }
        return true
    }
}
