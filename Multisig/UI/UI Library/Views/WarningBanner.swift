//
//  WarningBanner.swift
//  Multisig
//
//  Created by Mouaz on 8/22/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class WarningBanner: UINibView {

    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var accessoryImageView: UIImageView!
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet private weak var trailingConstraint: NSLayoutConstraint!

    private var onClick: (() ->())?
    override func commonInit() {
        super.commonInit()
        clipsToBounds = true
        layer.cornerRadius = 8

        actionButton.setTitle("", for: .normal)
        titleLabel.setStyle(.calloutMediumPrimary)
        descriptionLabel.setStyle(.subheadlineSecondary)
        infoLabel.setStyle(.calloutMediumPrimary)
    }

    func set(image: UIImage? = nil,
             title: String? = nil,
             description: String? = nil,
             info: String? = nil,
             accessory: UIImage? = nil,
             backgroundColor: UIColor = .warningBackground,
             onClick: (() ->())? = nil) {
        assert(title != nil || description != nil)

        if let image = image {
            iconImageView.image = image
        }

        accessoryImageView.isHidden = accessory == nil
        accessoryImageView.image = accessory
        trailingConstraint.constant = accessory == nil ? 16 : 0
        
        titleLabel.text = title
        titleLabel.isHidden = title == nil

        infoLabel.text = info
        infoLabel.isHidden = info == nil

        descriptionLabel.text = description
        descriptionLabel.isHidden = description == nil

        self.backgroundColor = backgroundColor
        self.onClick = onClick

        layoutIfNeeded()
    }

    @IBAction func actionButtonClicked(_ sender: Any) {
        onClick?()
    }
}
