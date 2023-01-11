//
//  SwitchDetailedTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class SwitchDetailedTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var switchControl: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.headline)
        detailLabel.setStyle(.callout)
    }

    func setOn(_ on: Bool, animated: Bool = true) {
        switchControl.setOn(on, animated: animated)
    }

    var text: String? {
        get { titleLabel?.text }
        set { titleLabel?.text = newValue }
    }

    var detailText: String? {
        get { detailLabel?.text }
        set { detailLabel?.text = newValue }
    }
}
