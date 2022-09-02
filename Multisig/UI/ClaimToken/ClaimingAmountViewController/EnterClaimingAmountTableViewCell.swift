//
//  EnterClaimingAmountTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 6/29/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterClaimingAmountTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var amountTextField: TokenAmountField!
    @IBOutlet private weak var maxButton: UIButton!

    private var maxValue: String?
    private var onClaim: ((String) -> ())?

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = "How much do you want to claim?"
        descriptionLabel.text = "Select all tokens or custom amount."

        titleLabel.setStyle(GNOTextStyle.title5.weight(.semibold))
        descriptionLabel.setStyle(.secondary)
        maxButton.setText("Max", .primary)
        amountTextField.setToken(image: UIImage(named: "ico-safe-token-logo"), amount: "0")
    }

    @IBAction func maxButtonTouched(_ sender: Any) {
        amountTextField.balance = maxValue ?? "0"
    }

    func set(value: String, maxValue: String) {
        amountTextField.balance = value
        self.maxValue = maxValue
    }
}
