//
//  TokenAmountField.swift
//  Multisig
//
//  Created by Vitaly Katz on 20.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class TokenAmountField: UINibView {
    
    @IBOutlet weak var borderImage: UIImageView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    var balance: String {
        get { amountTextField.text ?? "" }
        set { amountTextField.text = newValue }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        symbolLabel.setStyle(.tertiary)
        amountTextField.setStyle(.primary)
        amountTextField.placeholder = "Amount"
        errorLabel.setStyle(.error)
        errorLabel.isHidden = true
    }
    
    func showToken(symbol: String, logoURL: String? = nil, amount: String = "") {
        iconImage.setCircleShapeImage(url: URL(string: logoURL ?? ""), placeholder:  UIImage(named: "ico-token-placeholder")!)
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
        
        let decimalSeparator = Locale.autoupdatingCurrent.decimalSeparator ?? "."
        let inverseSet = CharacterSet(charactersIn:"0123456789").inverted
        let components = string.components(separatedBy: inverseSet)
        let filtered = components.joined(separator: "")
        if filtered == string {
            return true
        } else {
           if string.contains(decimalSeparator) {
           let countdots = textField.text!.components(separatedBy: decimalSeparator).count - 1
           if countdots == 0 {
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
