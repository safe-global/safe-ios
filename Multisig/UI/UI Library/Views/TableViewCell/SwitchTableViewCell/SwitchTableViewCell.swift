//
//  SwitchTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 2/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var switchControl: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.headline)
    }

    func setText(_ text: String?) {
        titleLabel.text = text
    }

    func setOn(_ on: Bool, animated: Bool = true) {
        switchControl.setOn(on, animated: animated)
    }
}
