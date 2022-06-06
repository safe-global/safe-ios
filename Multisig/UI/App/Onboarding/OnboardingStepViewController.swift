//
//  OnboardingStepViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/5/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingStepViewController: UIViewController {
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var skipButton: UIButton!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!

    private var onSkip: (() -> Void)?
    private var step: OnboardingStep!

    convenience init(step: OnboardingStep, onSkip: (() -> Void)? = nil) {
        self.init(namedClass: OnboardingStepViewController.self)

        self.step = step
        self.onSkip = onSkip
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = step.title
        descriptionLabel.text = step.description
        titleLabel.setStyle(.primary)
        imageView.image = step.image
        backgroundImageView.image = step.backgroundImage
        skipButton.isHidden = onSkip == nil
        skipButton.setText("Skip", .primary)
    }

    @IBAction func skipButtonTouched(_ sender: Any) {
        onSkip?()
    }
}

struct OnboardingStep {
    let title: String
    let description: String
    let image: UIImage
    let backgroundImage: UIImage?
}
