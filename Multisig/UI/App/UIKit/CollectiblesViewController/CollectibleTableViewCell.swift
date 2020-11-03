//
//  CollectibleTableViewCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class CollectibleTableViewCell: UITableViewCell {
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellNameLabel: UILabel!
    @IBOutlet weak var cellDescriptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellNameLabel.setStyle(.headline)
        cellDescriptionLabel.setStyle(.body)
    }

    func configure(collectible: CollectibleViewModel) {
        cellNameLabel.text = collectible.name
        cellDescriptionLabel.text = collectible.description
        let placeholder = #imageLiteral(resourceName: "ico-collectible-placeholder")
        if let url = collectible.imageURL {
            cellImageView.kf.setImage(with: url, placeholder: placeholder)
        } else {
            cellImageView.image = placeholder
        }
    }
}
