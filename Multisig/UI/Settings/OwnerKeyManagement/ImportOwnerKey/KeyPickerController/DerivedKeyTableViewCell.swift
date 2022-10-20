//
//  DerivedKeyTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class DerivedKeyTableViewCell: UITableViewCell {
    @IBOutlet private weak var leftLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var addressView: AddressInfoView!

    override func awakeFromNib() {
        super.awakeFromNib()
        leftLabel.setStyle(.body)
        iconImageView.tintColor = .primary
        addressView.copyEnabled = false
    }

    func setLeft(_ text: String?) {
        leftLabel.text = text
    }

    func setAddress(_ address: Address, label: String? = nil) {
        addressView.setAddress(address, label: label)
    }

    func setSelected(_ selected: Bool) {
        iconImageView.alpha = selected ? 1 : 0
    }

    func setEnabled(_ enabled: Bool) {
        contentView.alpha = enabled ? 1 : 0.5
    }
}
