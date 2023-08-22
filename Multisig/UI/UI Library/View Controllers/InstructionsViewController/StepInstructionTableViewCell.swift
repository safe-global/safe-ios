//
//  StepInstructionTableViewCell.swift
//  Multisig
//
//  Created by Dirk Jäckel on 22.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class StepInstructionTableViewCell: UITableViewCell {
    @IBOutlet weak var circleLabel: UILabel!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var verticalBarView: UIImageView!
    @IBOutlet weak var contentViewTopPaddingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        setStyles()
    }

    func setStyles(circleStyle: GNOTextStyle = .subheadlineSecondary,
                   headerStyle: GNOTextStyle = .headline,
                   descriptionStyle: GNOTextStyle = .callout,
                   verticalBarViewHidden: Bool = false,
                   topPadding: CGFloat = 0) {
        verticalBarView.isHidden = verticalBarViewHidden
        descriptionLabel.setStyle(descriptionStyle)
        circleLabel.setStyle(circleStyle)
        headerLabel.setStyle(headerStyle)
        contentViewTopPaddingConstraint.constant = topPadding
    }
}
