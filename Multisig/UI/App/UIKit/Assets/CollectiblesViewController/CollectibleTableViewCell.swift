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
    @IBOutlet private weak var cellSVGView: SVGView!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellNameLabel.setStyle(.headline)
        cellDescriptionLabel.setStyle(.body)
        cellSVGView.layer.maskedCorners = .
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cellSVGView.isHidden = true
    }

    func setName(_ value: String) {
        cellNameLabel.text = value
    }

    func setDescription(_ value: String) {
        cellDescriptionLabel.text = value
    }

    func setImage(with URL: URL?, placeholder: UIImage) {
        cellSVGView.isHidden = true
        if let url = URL {

            if url.pathExtension.caseInsensitiveCompare("svg") == .orderedSame {
                cellSVGView.setPlaceholder(placeholder)
                cellSVGView.isHidden = false
                cellSVGView.setSVG(url: url)
            } else {
                cellImageView.kf.setImage(with: url, placeholder: placeholder)
            }
        } else {
            cellImageView.image = placeholder
        }
    }
}
