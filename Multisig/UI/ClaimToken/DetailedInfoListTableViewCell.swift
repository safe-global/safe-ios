//
//  DetailedInfoListTableViewCell.swift
//  Multisig
//
//  Created by Mouaz on 9/7/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailedInfoListTableViewCell: UITableViewCell {

    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.headline)
        descriptionLabel.setStyle(.secondary)
    }

    func set(title: String?, description: String?) {
        titleLabel.text = title
        descriptionLabel.text = description
        titleLabel.isHidden = title == nil
        descriptionLabel.isHidden = description == nil
        setNeedsLayout()
    }
}
