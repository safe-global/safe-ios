//
//  AddOwnerViaSocialViewController.swift
//  Multisig
//
//  Created by Mouaz on 9/1/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit
import Lottie

class AddOwnerViaSocialViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var appleButton: UIButton!
    @IBOutlet private weak var googleButton: UIButton!

    var onAppleAction: () -> () = {}
    var onGoogleAction: () -> () = {}

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Create or import with Google or Apple ID"
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true

        appleButton.setText("Continue with Apple ID", .filled)
        googleButton.setText("Continue with Google", .filled)
        titleLabel.setStyle(.body)
        ViewControllerFactory.makeMultiLinesNavigationBar(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.chooseSocialAccountType)
    }

    @IBAction func googleButtonTouched(_ sender: Any) {
        Tracker.trackEvent(.userContinueGoogle)
        onGoogleAction()
    }

    @IBAction func appleButtonTouched(_ sender: Any) {
        Tracker.trackEvent(.userContinueApple)
        onAppleAction()
    }
}
