//
//  CreatePasswordSuggestionViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 08.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class CreatePasscodeSuggestionViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var notNowButton: UIButton!

    var onExit: (() -> Void)!

    @IBAction func onCreate(_ sender: Any) {
        let passcodeVC = CreatePasscodeViewController()
        passcodeVC.completion = onExit
        show(passcodeVC, sender: nil)
        Tracker.trackEvent(.userPasscodeSuggestionAccepted)
    }

    @IBAction func onNotNow(_ sender: Any) {
        onExit?()
        Tracker.trackEvent(.userPasscodeSuggestionRejected)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hidesBottomBarWhenPushed = true

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
