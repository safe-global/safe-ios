//
//  AddOwnerKeyCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddOwnerKeyCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.primary)
        subtitleLabel.setStyle(.footnote2)
    }

    func set(title: String) {
        titleLabel.text = title
    }

    func set(subtitle: String) {
        subtitleLabel.text = subtitle
    }
}
