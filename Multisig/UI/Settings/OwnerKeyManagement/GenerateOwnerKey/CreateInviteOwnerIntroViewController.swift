//
//  AddGeneratedKeyAsOwnerIntroViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/9/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class CreateInviteOwnerIntroViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var notThisTimeButton: UIButton!

    var onShare: (() -> ())!
    var onSkip: (() -> ())!
    convenience init(onShare: @escaping () -> (), onSkip: @escaping () -> ()) {
        self.init(namedClass: CreateInviteOwnerIntroViewController.self)
        self.onSkip = onSkip
        self.onShare = onShare
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.setStyle(.title5)
        descriptionLabel.setStyle(.secondary)
        shareButton.setText("Share link", .filled)
        notThisTimeButton.setText("Not this time", .primary)
    }

    @IBAction func didTapShareButton(_ sender: Any) {
        onShare?()
    }

    @IBAction func didTapNotThisTimeButton(_ sender: Any) {
        onSkip?()
    }
}
