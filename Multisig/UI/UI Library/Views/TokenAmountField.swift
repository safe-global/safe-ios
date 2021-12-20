//
//  TokenAmountField.swift
//  Multisig
//
//  Created by Vitaly Katz on 20.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class TokenAmountField: UINibView {

    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var amountLabel: UITextField!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func commonInit() {
        super.commonInit()
    }
}
