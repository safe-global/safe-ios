//
//  AvailableClaimingAmountTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 6/29/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class AvailableClaimingAmountTableViewCell: UITableViewCell {
    @IBOutlet private weak var totalAllocationLabel: UILabel!

    @IBOutlet private weak var claimableNowContainerView: UIView!
    @IBOutlet private weak var claimableNowTitleLabel: UILabel!
    @IBOutlet private weak var claimableNowTotalAvailalbleTitleLabel: UILabel!
    @IBOutlet private weak var claimableNowTotalAvailalbleValueLabel: UILabel!

    @IBOutlet private weak var claimableInFutureContainerView: UIView!
    @IBOutlet private weak var claimableInFutureTileLabel: UILabel!
    @IBOutlet private weak var claimableInFutureTotalAvailalbleTitleLabel: UILabel!
    @IBOutlet private weak var claimableInFutureTotalAvailalbleValueLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        claimableNowContainerView.layer.borderWidth = 2
        claimableNowContainerView.layer.cornerRadius = 10
        claimableNowContainerView.layer.borderColor = UIColor.clear.cgColor

        claimableInFutureContainerView.layer.borderWidth = 2
        claimableInFutureContainerView.layer.cornerRadius = 10
        claimableInFutureContainerView.layer.borderColor = UIColor.clear.cgColor

        claimableNowTitleLabel.setStyle(.headline)
        claimableInFutureTileLabel.setStyle(GNOTextStyle.Updated.background)

        claimableNowTotalAvailalbleTitleLabel.setStyle(GNOTextStyle.Updated.border)
        claimableNowTotalAvailalbleValueLabel.setStyle(.title6)

        claimableInFutureTotalAvailalbleTitleLabel.setStyle(.secondary)
        claimableInFutureTotalAvailalbleValueLabel.setStyle(GNOTextStyle.Updated.whiteTitle)
        totalAllocationLabel.setStyle(.footnote4)
    }

    func set(claimableNowUserAirdropValue: String,
             claimableNowEcosystemAirdropValue: String,
             claimableNowTotal: String,
             claimableInFutureUserAirdropValue: String,
                      claimableInFutureEcosystemAirdropValue: String,
                      claimableInFutureTotal: String) {
        claimableNowTotalAvailalbleValueLabel.text = claimableNowTotal

        claimableInFutureTotalAvailalbleValueLabel.text = claimableInFutureTotal
    }
}
