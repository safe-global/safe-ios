//
//  AddOwnerKeyCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddOwnerKeyCell: UITableViewCell {
    enum Style {
        case normal
        case highlighted
    }

    @IBOutlet private weak var detailsImageView: UIImageView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var backgroundColorView: StyledView!
    @IBOutlet private weak var borderImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.headline)
    }

    func set(title: String) {
        titleLabel.text = title
    }

    func set(iconName: String) {
        iconImageView.image = UIImage(named: iconName)
    }

    func set(image: UIImage) {
        iconImageView.image = image
    }

    func set(detailsImage: UIImage?) {
        detailsImageView.image = detailsImage
        detailsImageView.isHidden = detailsImage == nil
    }

    func set(style: Style) {
        switch style {
        case .normal:
            backgroundColorView.backgroundColor = .clear
            borderImageView.isHidden = false
            titleLabel.setStyle(.headline)
        case .highlighted:
            backgroundColorView.backgroundColor = .borderSelected
            borderImageView.isHidden = true
            titleLabel.setStyle(.headlinePrimaryInverted)
        }
    }
}
