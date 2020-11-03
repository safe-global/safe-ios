//
//  TotalBalanceTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 03.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class TotalBalanceTableViewCell: UITableViewCell {
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        mainLabel.setStyle(.headline)
        detailLabel.setStyle(.headline)
    }

    func setMainText(_ value: String) {
        mainLabel.text = value
    }

    func setDetailText(_ value: String) {
        detailLabel.text = value
    }
}

