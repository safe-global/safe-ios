//
//  ValueChangeTableViewCell.swift
//  Multisig
//
//  Created by Vitaly on 28.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ValueChangeTableViewCell: UITableViewCell {

    @IBOutlet weak var actionTitle: UILabel!
    @IBOutlet weak var valueBefore: UILabel!
    @IBOutlet weak var valueAfter: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        actionTitle.setStyle(.secondary)
        valueBefore.setStyle(.tertiary)
        valueAfter.setStyle(.primary)
    }

    func set(title: String, valueBefore: String, valueAfter: String) {
        self.actionTitle.text = title
        self.valueBefore.text = valueBefore
        self.valueAfter.text = valueAfter
    }
}
