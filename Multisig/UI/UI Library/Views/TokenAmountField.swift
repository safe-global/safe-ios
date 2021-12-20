//
//  TokenAmountField.swift
//  Multisig
//
//  Created by Vitaly Katz on 20.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class TokenAmountField: UINibView {
    
    var onTap: () -> Void = { }

    @IBOutlet weak var borderImage: UIImageView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var amountLabel: UITextField!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func commonInit() {
        super.commonInit()
    }
    
    override func awakeFromNib() {
        symbolLabel.setStyle(.tertiary)
        amountLabel.setStyle(.primary)
        amountLabel.placeholder = "Amount"
        errorLabel.setStyle(.error)
        errorLabel.isHidden = true
    }
    
    func showToken(token: TokenBalance, showBalance: Bool = false) {
        symbolLabel.text = token.symbol
        if showBalance {
            //TODO: format balance?
            amountLabel.text = token.balance
        }
        borderImage.tintColor = .gray4
        errorLabel.isHidden = true
    }
    
    func showError(message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        borderImage.tintColor = .error
    }
    
    @IBAction func didTapField(_ sender: Any) {
        onTap()
    }
    
    @IBAction func didTouchUp(_ sender: Any) {
        
    }
    
    @IBAction func didTouchDown(_ sender: Any) {
        
    }
}
