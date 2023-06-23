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
        addressInfoView.setAddress("0x1EF905613bd3ec793A2f84EbbCE6b2d372418405", label: "My Safe Account")
        addressInfoView.backgroundColor = .backgroundLightGreen
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @IBAction private func continueButtonTouched(_ sender: Any) {

    }
}
