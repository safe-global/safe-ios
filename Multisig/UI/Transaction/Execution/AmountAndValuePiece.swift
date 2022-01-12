//
//  AmountAndValuePiece.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class AmountAndValuePiece: UINibView {
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var fiatAmountLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        amountLabel.setStyle(.primary)
        fiatAmountLabel.setStyle(.caption1.weight(.regular))
    }

    func setAmount(_ value: String?) {
        amountLabel.text = value
    }

    func setFiatAmount(_ value: String?) {
        fiatAmountLabel.text = value
    }
}
