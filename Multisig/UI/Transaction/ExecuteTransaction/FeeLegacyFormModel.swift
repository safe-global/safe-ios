//
//  FeeLegacyFormModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Solidity
import Ethereum
import UIKit

class FeeLegacyFormModel: FormModel {
    weak var delegate: FieldDelegate? = nil
    var isValid: Bool?

    var nonce: Sol.UInt64?
    var minimalNonce: Sol.UInt64!
    var gas: Sol.UInt64?
    var gasPriceInWei: Sol.UInt256?

    let gigaweiDecimals = 9

    var totalFeeInWei: Sol.UInt256? {
        guard let gas = gas, let gasPrice = gasPriceInWei else { return nil }
        let (partialResult, overflow) = Sol.UInt256(gas).multipliedReportingOverflow(by: gasPrice)
        if overflow { return nil}
        return partialResult
    }

    var nativeCurrency: ChainToken

    var gasField: LabeledTextField!
    var nonceField: LabeledTextField!
    var gasPriceField: LabeledTextField!

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

    var gasPriceInGigaweiText: String? {
        guard let gasPrice = gasPriceInWei else { return nil }
        let amount = Eth.TokenAmount(value: gasPrice, decimals: gigaweiDecimals)
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

    init(nonce: Sol.UInt64?, minimalNonce: Sol.UInt64 = 0, gas: Sol.UInt64?, gasPriceInWei: Sol.UInt256?, nativeCurrency: ChainToken) {
        self.nonce = nonce
        self.minimalNonce = minimalNonce
        self.gas = gas
        self.gasPriceInWei = gasPriceInWei
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


        gasPriceField = LabeledTextField()
        gasPriceField.infoLabel.setText(
            "Gas price (GWEI)",
            description: "Price per 1 gas in Gwei price units",
            style: .headline
        )
        gasPriceField.gnoTextField.setPlaceholder("Gas price (GWEI)")
        gasPriceField.gnoTextField.text = gasPriceInGigaweiText
        gasPriceField.gnoTextField.textField.keyboardType = .decimalPad
        gasPriceField.validator = DecimalTextValidator()
        gasPriceField.fieldDelegate = delegate

        gasPriceField.setCaption(totalFeeInNativeCoinText)

        helpField = HyperlinkButtonView()
        helpField.setText("How do I configure these details manually?")
        helpField.url = App.configuration.help.advancedTxParamsURL

        return [nonceField, gasField, gasPriceField, helpField]
    }

    func validate() {
        let allValidations = [validateNonce(), validateGas(), validateGasPrice(), validateTotalFee()]
        let allFieldsAreValid = allValidations.reduce(true) { partialResult, value in
            partialResult && value
        }
        self.isValid = allFieldsAreValid

        gasPriceField.setCaption(totalFeeInNativeCoinText)

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

    func validateGasPrice() -> Bool {
        gasPriceField.gnoTextField.setErrorText(nil)

        guard let text = gasPriceField.text, !text.isEmpty else {
            gasPriceField.gnoTextField.setErrorText("This value is required")
            return false
        }

        guard let amount = Eth.TokenAmount<Sol.UInt256>(text, radix: 10, decimals: gigaweiDecimals) else {
            gasPriceField.gnoTextField.setErrorText("Value is not a valid number")
            return false
        }

        gasPriceInWei = amount.value
        return true
    }

    func validateTotalFee() -> Bool {
        guard totalFeeInWei != nil else {
            gasField.gnoTextField.setErrorText("Total fee is too high")
            gasPriceField.gnoTextField.setErrorText("Total fee is too high ")
            return false
        }
        return true
    }
}
