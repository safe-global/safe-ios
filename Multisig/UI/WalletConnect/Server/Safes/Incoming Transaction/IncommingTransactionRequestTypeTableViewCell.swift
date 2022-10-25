//
//  IncommingTransactionRequestTypeTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 7/13/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class IncommingTransactionRequestTypeTableViewCell: UITableViewCell {

    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.setStyle(.headline)
        descriptionLabel.setStyle(.body)
    }

    func set(imageName: String, name: String, description: String? = nil) {
        iconImageView.image = UIImage(named: imageName) ?? UIImage(named: "ico-custom-tx")
        nameLabel.text = name
        descriptionLabel.text = description
        descriptionLabel.isHidden = description == nil
    }
}
