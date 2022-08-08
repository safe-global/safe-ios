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
    @IBOutlet private weak var claimButton: UIButton!
    @IBOutlet private weak var addressInfoView: AddressInfoView!
    @IBOutlet private weak var delegateToLabel: UILabel!
    @IBOutlet private weak var addressContainerView: UIView!

    private var maxValue: String?
    private var onClaim: ((String) -> ())?

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(GNOTextStyle.Updated.title)
        descriptionLabel.setStyle(.secondary)
        maxButton.setText("Max", .primary)
        claimButton.setText("Claim tokens", .filled)
        addressContainerView.layer.borderWidth = 2
        addressContainerView.layer.cornerRadius = 10
        addressContainerView.layer.borderColor = UIColor.border.cgColor
        delegateToLabel.setStyle(.secondary)

        amountTextField.setToken(image: UIImage(named: "ico-safe-token-logo"), amount: "0")
    }

    @IBAction func maxButtonTouched(_ sender: Any) {
        amountTextField.balance = maxValue ?? "0"
    }

    @IBAction func claimButtonTouched(_ sender: Any) {
        onClaim?(amountTextField.balance)
    }

    func set(value: String, maxValue: String, guardian: Guardian, onClaim: @escaping (String) -> ()) {
        amountTextField.balance = value
        self.maxValue = maxValue
        addressInfoView.setAddress(guardian.address,
                                   ensName: guardian.ensName,
                                   label: guardian.name,
                                   imageUri: guardian.imageURL,
                                   showIdenticon: true,
                                   badgeName: nil,
                                   browseURL: nil,
                                   prefix: nil)
        addressInfoView.copyEnabled = false

        self.onClaim = onClaim
    }
}
