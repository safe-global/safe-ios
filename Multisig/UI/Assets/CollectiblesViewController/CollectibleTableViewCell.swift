//
//  CollectibleTableViewCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class CollectibleTableViewCell: UITableViewCell {
    @IBOutlet private weak var cellNameLabel: UILabel!
    @IBOutlet private weak var cellDescriptionLabel: UILabel!
    @IBOutlet private weak var cellImageView: WebImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellNameLabel.setStyle(.headline)
        cellDescriptionLabel.setStyle(.body)
        cellImageView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        cellImageView.layer.cornerRadius = 8
        cellImageView.clipsToBounds = true
    }
    
    func setName(_ value: String) {
        cellNameLabel.text = value
    }

    func setDescription(_ value: String) {
        cellDescriptionLabel.text = value
    }

    func setImage(with url: URL?, placeholder: UIImage) {
        cellImageView.setImage(url: url, placeholder: placeholder)
    }
}
