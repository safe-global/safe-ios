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
    @IBOutlet private (set) weak var amountTextField: UITextField!
    @IBOutlet private weak var errorLabel: UILabel!

    var borderColorNormal: UIColor = .border
    var borderColorError: UIColor = .error
    var borderColorActive: UIColor = .borderSelected
    
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
        amountTextField.setStyle(.body)
        amountTextField.placeholder = "Amount"
        errorLabel.setStyle(.calloutError)
        errorLabel.isHidden = true
        errorLabel.text = nil
        updateBorder()
    }
    
    func setToken(logoURL: URL? = nil, amount: String = "") {
        iconImage.setCircleShapeImage(url: logoURL, placeholder:  UIImage(named: "ico-token-placeholder")!)
        amountTextField.text = amount
        errorLabel.isHidden = true
        updateBorder()
    }

    func setToken(image: UIImage? = nil, amount: String = "") {
        iconImage.image = image ?? UIImage(named: "ico-token-placeholder")
        amountTextField.text = amount
        errorLabel.isHidden = true
        updateBorder()
    }
    
    func showError(message: String?) {
        if let message = message {
            errorLabel.text = message
            errorLabel.isHidden = false
        } else {
            errorLabel.text = nil
            errorLabel.isHidden = true
        }
        updateBorder()
    }

    func updateBorder() {
        borderImage.tintColor = textFieldBorderColor
    }

    var textFieldBorderColor: UIColor {
        if errorLabel.text != nil {
            return borderColorError
        }
        return amountTextField.isFirstResponder ? borderColorActive : borderColorNormal
    }
}
