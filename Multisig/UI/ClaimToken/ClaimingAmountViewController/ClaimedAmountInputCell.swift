//
//  ClaimedAmountInputCell.swift
//  Multisig
//
//  Created by Moaaz on 6/29/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ClaimedAmountInputCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var amountTextField: TokenAmountField!
    @IBOutlet private weak var maxButton: UIButton!

    var didTapMax: () -> Void = { }

    var maxValue: String?
    var balance: String = "" {
        didSet {
            amountTextField.balance = balance
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = "How much do you want to claim?"
        descriptionLabel.text = "Select all tokens or custom amount."

        titleLabel.setStyle(GNOTextStyle.title5.weight(.semibold))
        descriptionLabel.setStyle(.secondary)
        maxButton.setText("Max", .primary)
        amountTextField.setToken(image: UIImage(named: "ico-safe-token-logo"))
    }

    @IBAction func maxButtonTouched(_ sender: Any) {
        amountTextField.balance = maxValue ?? "0"
        didTapMax()
    }

}
