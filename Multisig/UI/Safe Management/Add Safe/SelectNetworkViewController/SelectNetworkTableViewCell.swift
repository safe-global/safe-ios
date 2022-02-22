//
//  SelectNetworkTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 6/25/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectNetworkTableViewCell: UITableViewCell {
    @IBOutlet weak var colorImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.setStyle(.primary)
    }

    func setText(_ text: String?) {
        nameLabel.text = text
    }

    func setIndicatorColor(hex: String) {
        setIndicatorColor(UIColor(hex: hex))
    }

    func setIndicatorColor(_ color: UIColor?) {
        colorImageView.tintColor = color
    }
}
