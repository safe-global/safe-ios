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
    
    @IBAction func didTapField(_ sender: Any) {
        onTap()
    }
    
    @IBAction func didTouchUp(_ sender: Any) {
        
    }
    
    @IBAction func didTouchDown(_ sender: Any) {
        
    }
}
