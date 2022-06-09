//
//  AddGeneratedKeyAsOwnerIntroViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/9/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class CreateInviteOwnerIntroViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var notThisTimeButton: UIButton!

    var onShare: (() -> ())?

    var onSkip: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        presentationController?.delegate = self
        titleLabel.setStyle(.primary)
        descriptionLabel.setStyle(.secondary)
        shareButton.setText("Share link", .filled)
        notThisTimeButton.setText("Not this time", .plain)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.addAsOwnerIntro)
    }

    // Called when user swipes down the modal screen
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onSkip?()
    }

    @IBAction func didTapShareButton(_ sender: Any) {
        onShare?()
    }

    @IBAction func didTapNotThisTimeButton(_ sender: Any) {
        Tracker.trackEvent(.addAsOwnerIntroSkipped)
        onSkip?()
    }
}
