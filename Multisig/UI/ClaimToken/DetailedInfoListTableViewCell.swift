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
        descriptionLabel.setStyle(.body)
    }

    func set(title: String?, description: String?) {
        titleLabel.text = title
        titleLabel.isHidden = title == nil

        descriptionLabel.isHidden = description == nil
        if let description = description {
            let attrString = NSMutableAttributedString(string: description, attributes: GNOTextStyle.body.attributes)
            attrString.paragraph()
            descriptionLabel.attributedText = attrString
        }

        setNeedsLayout()
    }
}
