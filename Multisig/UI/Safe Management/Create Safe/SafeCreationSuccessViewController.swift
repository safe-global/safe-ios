//
//  SafeCreationSuccessViewController.swift
//  Multisig
//
//  Created by Mouaz on 6/21/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit
import Lottie

class SafeCreationSuccessViewController: UIViewController {
    @IBOutlet private weak var animationView: LottieAnimationView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var continueButton: UIButton!
    @IBOutlet private weak var addressInfoView: AddressInfoView!

    var safe: Safe!
    var chain: Chain!
    var onContinue: () -> () = {}
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.setStyle(.title1)
        bodyLabel.setStyle(.body)

        animationView.animation = LottieAnimation.named(isDarkMode ? "successAnimationDark" : "successAnimation",
                                                  animationCache: nil)
        animationView.contentMode = .scaleAspectFit
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.play()
        continueButton.setText("Continue", .filled)

        addressInfoView.setAddress(Address("0xEa3290590Dd491739f5F731266631A2649eBa661"),
                                   label: "My Safe Account",
                                   browseURL: chain.browserURL(address: "0xEa3290590Dd491739f5F731266631A2649eBa661"))

        addressInfoView.backgroundColor = .backgroundLightGreen
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.screenCreatingComplete)
    }

    @IBAction private func continueButtonTouched(_ sender: Any) {
        Tracker.trackEvent(.userCreatingCompleteContinue)
        onContinue()
    }
}
