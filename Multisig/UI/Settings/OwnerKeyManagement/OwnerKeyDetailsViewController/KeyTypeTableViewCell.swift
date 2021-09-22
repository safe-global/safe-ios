//
//  KeyTypeTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 9/22/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class KeyTypeTableViewCell: UITableViewCell {
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.setStyle(.primary)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        iconImageView.layer.cornerRadius = iconImageView.frame.height / 2
        iconImageView.clipsToBounds = true
    }

    func set(name: String, iconName: String) {
        nameLabel.text = name
        iconImageView.image = UIImage(named: iconName)
    }
}
