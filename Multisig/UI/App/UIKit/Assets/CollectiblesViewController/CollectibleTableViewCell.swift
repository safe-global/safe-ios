//
//  CollectibleTableViewCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class CollectibleTableViewCell: UITableViewCell {
    @IBOutlet private weak var cellImageView: UIImageView!
    @IBOutlet private weak var cellNameLabel: UILabel!
    @IBOutlet private weak var cellDescriptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellNameLabel.setStyle(.headline)
        cellDescriptionLabel.setStyle(.body)
    }

    func setName(_ value: String) {
        cellNameLabel.text = value
    }

    func setDescription(_ value: String) {
        cellDescriptionLabel.text = value
    }

    func setImage(with URL: URL?, placeholder: UIImage) {
        if let url = URL {
            cellImageView.kf.setImage(with: url, placeholder: placeholder)
        } else {
            cellImageView.image = placeholder
        }
    }
}
