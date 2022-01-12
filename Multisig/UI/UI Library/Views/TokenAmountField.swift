//
//  TokenAmountField.swift
//  Multisig
//
//  Created by Vitaly Katz on 20.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class TokenAmountField: UINibView {
    
    @IBOutlet private weak var borderImage: UIImageView!
    @IBOutlet private weak var iconImage: UIImageView!
    @IBOutlet private weak var amountTextField: UITextField!
    @IBOutlet private weak var symbolLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    
    var balance: String {
        get { amountTextField.text ?? "" }
        set { amountTextField.text = newValue }
    }

    @IBInspectable var delegate: UITextFieldDelegate? {
        set { amountTextField.delegate = newValue }
        get { amountTextField.delegate }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        symbolLabel.setStyle(.tertiary)
        amountTextField.setStyle(.primary)
        amountTextField.placeholder = "Amount"
        errorLabel.setStyle(.error)
        errorLabel.isHidden = true
    }
    
    func setToken(symbol: String, logoURL: URL? = nil, amount: String = "") {
        iconImage.setCircleShapeImage(url: logoURL, placeholder:  UIImage(named: "ico-token-placeholder")!)
        symbolLabel.text = symbol
        amountTextField.text = amount
        borderImage.tintColor = .gray4
        errorLabel.isHidden = true
    }
    
    func showError(message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        borderImage.tintColor = .error
    }
}

// allow only decimal numbers to be entered in the amount field
extension TokenAmountField: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        let inverseSet = CharacterSet.decimalDigits.inverted
        let components = string.components(separatedBy: inverseSet)
        let filtered = components.joined(separator: "")
        if filtered == string {
            return true
        } else {
             //disallow negative amounts
            if string.contains("-") {
                return false
            }
            if string.contains(decimalSeparator) {
                let countdots = (textField.text?.components(separatedBy: decimalSeparator).count ?? 0) - 1
                if countdots <= 0 {
                    return true
                } else {
                    if countdots > 0 && string == decimalSeparator {
                        return false
                    } else {
                        return true
                    }
                }
            } else {
                return false
            }
        }
    }
}
