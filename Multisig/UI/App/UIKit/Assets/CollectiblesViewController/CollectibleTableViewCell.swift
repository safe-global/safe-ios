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
    @IBOutlet private weak var cellSVGView: SVGView!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellNameLabel.setStyle(.headline)
        cellDescriptionLabel.setStyle(.body)
        cellSVGView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        cellSVGView.layer.cornerRadius = 8
        cellSVGView.clipsToBounds = true
    }
    
    func setName(_ value: String) {
        cellNameLabel.text = value
    }

    func setDescription(_ value: String) {
        cellDescriptionLabel.text = value
    }

    func setImage(with url: URL?, placeholder: UIImage) {
        cellSVGView.setImage(url: url, placeholder: placeholder)
    }
}
