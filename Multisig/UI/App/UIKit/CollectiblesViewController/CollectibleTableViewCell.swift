//
//  CollectibleTableViewCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class CollectibleTableViewCell: UITableViewCell {
    @IBOutlet weak var cellWrapperView: UIView!
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellNameLabel: UILabel!
    @IBOutlet weak var cellDescriptionLabel: UILabel!

    let cornerRadius: CGFloat = 8

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .gnoSystemWhite

        cellWrapperView.backgroundColor = .gnoSystemWhite
        cellWrapperView.layer.cornerRadius = cornerRadius
        cellWrapperView.layer.shadowColor = UIColor.gnoShadow.cgColor
        cellWrapperView.layer.shadowOpacity = 0.6
        cellWrapperView.layer.shadowOffset = .init(width: 1, height: 2)
        cellWrapperView.layer.shadowRadius = 6

        cellNameLabel.setStyle(.headline)
        cellDescriptionLabel.setStyle(.body)
        cellDescriptionLabel.numberOfLines = 3
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
