//
//  TotalBalanceTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 03.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class TotalBalanceTableViewCell: UITableViewCell {
//    @IBOutlet private weak var mainLabel: UILabel!
//    @IBOutlet private weak var detailLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
//        mainLabel.setStyle(.headline)
//        detailLabel.setStyle(.headline)
//
//        for label in [mainLabel, detailLabel] {
//            label?.text = nil
//        }
    }

    func setMainText(_ value: String) {
        //mainLabel.text = value
    }

    func setDetailText(_ value: String) {
        //detailLabel.text = value
    }
}

