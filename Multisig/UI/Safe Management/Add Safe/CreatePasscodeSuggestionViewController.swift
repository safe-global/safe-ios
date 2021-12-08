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

    var onExit: (() -> Void)?

    @IBAction func onCreate(_ sender: Any) {
    }

    @IBAction func onNotNow(_ sender: Any) {
        onExit?()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = UIImage(named: "keep-safe-secure")
        titleLabel.setStyle(.headline)
        subtitleLabel.setStyle(.primary)

        createButton.setText("Create password", .filled)
        notNowButton.setText("Not now", .primary)

        // If we show this screen, no more need in displaying the banner
        AppSetting.passcodeBannerDismissed = true
    }
}
