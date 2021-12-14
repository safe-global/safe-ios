//
//  CreatePasswordSuggestionViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 08.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class CreatePasscodeSuggestionViewController: UIViewController {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var createButton: UIButton!
    @IBOutlet private weak var notNowButton: UIButton!

    var onExit: (() -> Void)!

    @IBAction private func onCreate(_ sender: Any) {
        let passcodeVC = CreatePasscodeViewController()
        passcodeVC.completion = onExit
        show(passcodeVC, sender: nil)
        Tracker.trackEvent(.userPasscodeSuggestionAccepted)
    }

    @IBAction private func onNotNow(_ sender: Any) {
        onExit?()
        Tracker.trackEvent(.userPasscodeSuggestionRejected)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true
        navigationItem.title = nil

        imageView.image = UIImage(named: "keep-safe-secure")
        titleLabel.setStyle(.title3)
        subtitleLabel.setStyle(.callout)

        createButton.setText("Create passcode", .filled)
        notNowButton.setText("Not now", .primary)

        // If we show this screen, no more need in displaying the banner
        AppSettings.passcodeBannerDismissed = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.passcodeSuggestion)
    }
}
