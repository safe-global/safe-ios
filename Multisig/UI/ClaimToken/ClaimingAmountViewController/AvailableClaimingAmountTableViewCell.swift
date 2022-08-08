//
//  AvailableClaimingAmountTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 6/29/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class AvailableClaimingAmountTableViewCell: UITableViewCell {

    @IBOutlet private weak var claimableNowContainerView: UIView!
    @IBOutlet private weak var claimableNowTitleLabel: UILabel!
    @IBOutlet private weak var claimableNowUserAirdropTitleLabel: UILabel!
    @IBOutlet private weak var claimableNowUserAirdropValueLabel: UILabel!
    @IBOutlet private weak var claimableNowEcosystemAirdropTitleLabel: UILabel!
    @IBOutlet private weak var claimableNowEcosystemAirdropValueLabel: UILabel!
    @IBOutlet private weak var claimableNowTotalAvailalbleTitleLabel: UILabel!
    @IBOutlet private weak var claimableNowTotalAvailalbleValueLabel: UILabel!

    @IBOutlet private weak var claimableInFutureContainerView: UIView!
    @IBOutlet private weak var claimableInFutureitleLabel: UILabel!
    @IBOutlet private weak var claimableInFutureUserAirdropTitleLabel: UILabel!
    @IBOutlet private weak var claimableInFutureUserAirdropValueLabel: UILabel!
    @IBOutlet private weak var claimableInFutureEcosystemAirdropTitleLabel: UILabel!
    @IBOutlet private weak var claimableInFutureEcosystemAirdropValueLabel: UILabel!
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

        claimableNowTitleLabel.setStyle(.primary)
        claimableInFutureitleLabel.setStyle(GNOTextStyle.Updated.background)

        claimableNowUserAirdropTitleLabel.setStyle(.secondary)
        claimableNowEcosystemAirdropTitleLabel.setStyle(.secondary)
        claimableNowTotalAvailalbleTitleLabel.setStyle(.secondary)
        claimableNowUserAirdropValueLabel.setStyle(.primary)
        claimableNowEcosystemAirdropValueLabel.setStyle(.primary)
        claimableNowTotalAvailalbleValueLabel.setStyle(.title6)

        claimableInFutureUserAirdropTitleLabel.setStyle(GNOTextStyle.Updated.border)
        claimableInFutureEcosystemAirdropTitleLabel.setStyle(GNOTextStyle.Updated.border)
        claimableInFutureTotalAvailalbleTitleLabel.setStyle(GNOTextStyle.Updated.border)
        claimableInFutureUserAirdropValueLabel.setStyle(GNOTextStyle.Updated.background)
        claimableInFutureEcosystemAirdropValueLabel.setStyle(GNOTextStyle.Updated.background)
        claimableInFutureTotalAvailalbleValueLabel.setStyle(GNOTextStyle.Updated.whiteTitle)
    }

    func set(claimableNowUserAirdropValue: String,
             claimableNowEcosystemAirdropValue: String,
             claimableNowTotal: String,
             claimableInFutureUserAirdropValue: String,
                      claimableInFutureEcosystemAirdropValue: String,
                      claimableInFutureTotal: String) {
        claimableNowUserAirdropValueLabel.text = claimableNowUserAirdropValue
        claimableNowEcosystemAirdropValueLabel.text = claimableNowEcosystemAirdropValue
        claimableNowTotalAvailalbleValueLabel.text = claimableNowTotal

        claimableInFutureUserAirdropValueLabel.text = claimableInFutureUserAirdropValue
        claimableInFutureEcosystemAirdropValueLabel.text = claimableInFutureEcosystemAirdropValue
        claimableInFutureTotalAvailalbleValueLabel.text = claimableInFutureTotal
    }
}
