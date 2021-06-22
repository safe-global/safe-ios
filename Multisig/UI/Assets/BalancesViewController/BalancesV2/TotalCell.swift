//
//  TotalCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 03.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class TotalCell: UITableViewCell {
    var mainText: String? {
        get { mainLabel?.text }
        set { mainLabel?.text = newValue }
    }
    var detailText: String? {
        get { detailLabel?.text }
        set { detailLabel?.text = newValue }
    }

    @IBOutlet private weak var mainLabel: GSLabel!
    @IBOutlet private weak var detailLabel: GSLabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        mainLabel.style = .headline
        detailLabel.style = .headline

        mainText = "Total"
        detailText = nil
    }
}

