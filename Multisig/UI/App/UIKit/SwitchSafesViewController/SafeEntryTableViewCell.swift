//
//  SafeEntryTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 30.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeEntryTableViewCell: UITableViewCell {
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var selectorView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        mainLabel.setStyle(.headline)
        detailLabel.setStyle(GNOTextStyle.body.color(.gnoMediumGrey))
    }

    func setAddress(_ value: Address) {
        mainImageView.setAddress(value.hexadecimal)
        detailLabel.text = value.ellipsized()
    }

    func setName(_ value: String) {
        mainLabel.text = value
    }

    func setSelection(_ value: Bool) {
        selectorView.isHidden = !value
    }
}
