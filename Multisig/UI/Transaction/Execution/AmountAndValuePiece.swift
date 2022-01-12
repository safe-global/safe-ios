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
    @IBOutlet weak var stackView: UIStackView!

    override func commonInit() {
        super.commonInit()
        amountLabel.setStyle(.primary)
        fiatAmountLabel.setStyle(.caption1.weight(.regular))
        setStackAlignment(.trailing)
        setTextAlignment(.right)
    }

    func setAmount(_ value: String?) {
        amountLabel.text = value
    }

    func setFiatAmount(_ value: String?) {
        fiatAmountLabel.text = value
    }

    func setTextAlignment(_ value: NSTextAlignment) {
        amountLabel.textAlignment = value
        fiatAmountLabel.textAlignment = value
    }

    func setStackAlignment(_ value: UIStackView.Alignment) {
        stackView.alignment = value
    }
}
