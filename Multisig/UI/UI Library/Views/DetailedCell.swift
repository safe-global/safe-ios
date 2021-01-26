//
//  DetailedCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import Kingfisher

class DetailedCell: UITableViewCell {
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    static let rowHeight: CGFloat = 64

    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.setStyle(.headline)
        descriptionLabel.setStyle(GNOTextStyle.body.color(.gnoMediumGrey))
    }

    func setImage(url: URL?, placeholder: UIImage?) {
        guard let url = url else {
            iconImageView.image = placeholder
            return
        }
        iconImageView.kf.setImage(with: url, placeholder: placeholder)
    }

    func setHeader(_ text: String?) {
        headerLabel.text = text
    }

    func setDescription(_ text: String?) {
        descriptionLabel.text = text
    }
}
