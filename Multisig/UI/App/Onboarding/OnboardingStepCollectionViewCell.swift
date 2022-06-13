//
//  OnboardingStepCollectionViewCell.swift
//  Multisig
//
//  Created by Moaaz on 6/7/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingStepCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!

    static let identifier = "OnboardingStepCollectionViewCell"

    func configure(step: OnboardingStep) {
        titleLabel.text = step.title
        titleLabel.setStyle(.Updated.title)

        if let hightlightedText = step.description.highlightedText {
            descriptionLabel.attributedText = step.description.text.highlightRange(
                originalStyle: .secondary,
                highlightStyle: .primary.weight(.semibold),
                textToHightlight: hightlightedText
            )
        } else {
            descriptionLabel.text = step.description.text
            descriptionLabel.setStyle(.secondary)
        }
        imageView.image = step.image
        backgroundImageView.image = step.backgroundImage
    }

    override class func awakeFromNib() {
        super.awakeFromNib()
    }
}

struct OnboardingStep {
    let title: String
    let description: (text: String, highlightedText: String?)
    let image: UIImage
    let backgroundImage: UIImage?
}
