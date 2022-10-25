//
//  AllocationTotalCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.09.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class AllocationTotalCell: UITableViewCell {

    var text: String? {
        didSet {
            valueLabel.text = text
        }
    }

    @IBOutlet private weak var valueLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        valueLabel.setStyle(.footnote)
    }
}
