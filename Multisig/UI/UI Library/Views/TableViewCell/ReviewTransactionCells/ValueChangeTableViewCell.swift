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
    @IBOutlet weak var arrow: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        actionTitle.setStyle(.headlineSecondary)
        valueBefore.setStyle(.bodyTertiary)
        valueAfter.setStyle(.bodyPrimary)
    }

    func set(title: String, valueBefore: String, valueAfter: String) {
        self.actionTitle.text = title
        self.valueBefore.isHidden = false
        self.valueBefore.text = valueBefore
        self.arrow.isHidden = false
        self.valueAfter.text = valueAfter
    }

    func set(title: String, value: String) {
        self.actionTitle.text = title
        self.valueBefore.isHidden = true
        self.arrow.isHidden = true
        self.valueAfter.text = value
    }
}
