//
//  CreatingSocialKeyViewController.swift
//  Multisig
//
//  Created by Mouaz on 9/4/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit
import Lottie

class CreatingSocialKeyViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var animationView: LottieAnimationView!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.setStyle(.title1)

        animationView.animation = LottieAnimation.named(isDarkMode ? "safeCreationDark" : "safeCreation", animationCache: nil)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.play()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.creatingSocialKey)
    }
}
