//
//  SecurityFactorTableViewCell.swift
//  Multisig
//
//  Created by Mouaz on 8/9/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class SecurityFactorTableViewCell: UITableViewCell {

    @IBOutlet private weak var selectedImageView: UIImageView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var tagLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var detailsLabel: UILabel!
    @IBOutlet private weak var disclosureImageView: UIImageView!
    @IBOutlet private weak var borderImageView: UIImageView!

    static let rowHeight: CGFloat = 80

    override func awakeFromNib() {
        super.awakeFromNib()

        nameLabel.setStyle(.headline)
        tagLabel.setStyle(.subheadlineSecondary)
        valueLabel.setStyle(.callout)
        detailsLabel.setStyle(.callout)
    }

    func set(name: String, icon: UIImage, value: String? = nil, details: String? = nil, tag: String? = nil, selected: Bool = false, showDisclosure: Bool = true, bordered: Bool = false) {
        nameLabel.text = name
        valueLabel.text = value
        valueLabel.isHidden = value == nil
        detailsLabel.text = details
        detailsLabel.isHidden = details == nil
        tagLabel.text = tag
        tagLabel.isHidden = tag == nil
        selectedImageView.isHidden = !selected
        iconImageView.image = icon
        disclosureImageView.isHidden = !showDisclosure
        borderImageView.isHidden = !bordered
    }
}
