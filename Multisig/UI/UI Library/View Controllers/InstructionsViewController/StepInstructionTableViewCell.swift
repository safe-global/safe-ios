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

    override func awakeFromNib() {
        super.awakeFromNib()
        circleLabel.setStyle(.subhead.weight(.medium).color(.secondaryLabel))
        headerLabel.setStyle(.headline.weight(.medium))
        descriptionLabel.setStyle(.callout.weight(.regular).color(.secondaryLabel))
    }
}
