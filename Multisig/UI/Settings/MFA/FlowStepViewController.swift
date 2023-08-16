//
//  FlowStepViewController.swift
//  Multisig
//
//  Created by Mouaz on 8/10/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit
import Lottie

class FlowStepViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet weak var animationView: LottieAnimationView!
    @IBOutlet private weak var descriptionLabel: UILabel!

    private var titleText: String?
    private var descriptionText: String?
    private var actionText: String?
    private var image: String?
    private var animation: String?
    private var trackingEvent: TrackingEvent?

    var onDone: () -> Void = { }

    convenience init(
        titleText: String?,
        descriptionText: String?,
        actionText: String?,
        image: String?,
        animation: String?,
        trackingEvent: TrackingEvent? = nil,
        onDone: @escaping () -> Void
    ) {
        self.init(nibName: nil, bundle: nil)
        self.titleText = titleText
        self.descriptionText = descriptionText
        self.actionText = actionText
        self.image = image
        self.animation = animation
        self.trackingEvent = trackingEvent
        self.onDone = onDone
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(image != nil || animation != nil)
        titleLabel.setStyle(.title1)
        descriptionLabel.setStyle(.body)
        titleLabel.text = titleText
        descriptionLabel.text = descriptionText

        if let image = image {
            imageView.image = UIImage(named: image)
            animationView.isHidden = true
        } else if let animation = animation {
            imageView.isHidden = true
            animationView.animation = LottieAnimation.named(animation, animationCache: nil)
            animationView.contentMode = .scaleAspectFit
            animationView.backgroundBehavior = .pauseAndRestore
            animationView.play()
        }

        self.actionButton.setText(actionText, .filled)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let trackingEvent = trackingEvent {
            Tracker.trackEvent(trackingEvent)
        }
    }

    @IBAction private func actionButtonTouched(_ sender: Any) {
        onDone()
    }
}
