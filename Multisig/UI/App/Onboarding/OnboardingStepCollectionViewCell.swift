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
        if let highlightedText = step.title.highlightedText {
            titleLabel.attributedText = step.title.text.highlightRange(
                originalStyle: .title1,
                highlightStyle: .title1.color(.primary),
                textToHighlight: highlightedText
            )
        } else {
            titleLabel.text = step.title.text
            titleLabel.setStyle(.title1)
        }

        if let highlightedText = step.description.highlightedText {
            descriptionLabel.attributedText = step.description.text.highlightRange(
                originalStyle: .body,
                highlightStyle: .bodyPrimary,
                textToHighlight: highlightedText
            )
        } else {
            descriptionLabel.text = step.description.text
            descriptionLabel.setStyle(.body)
        }
        imageView.image = step.image
    }

    override class func awakeFromNib() {
        super.awakeFromNib()
    }
}

struct OnboardingStep {
    let title: (text: String, highlightedText: String?)
    let description: (text: String, highlightedText: String?)
    let image: UIImage
    let trackingEvent: TrackingEvent?
}
