//
//  SafeCreatingViewController.swift
//  Multisig
//
//  Created by Mouaz on 6/21/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit
import Lottie

class SafeCreatingViewController: UIViewController {

    @IBOutlet weak var animationView: LottieAnimationView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoView3: InfoView!
    @IBOutlet weak var infoView2: InfoView!
    @IBOutlet weak var infoView1: InfoView!

    var onSuccess: () -> () = {}
    var onViewDidLoad: () -> () = {}

    override func viewDidLoad() {
        super.viewDidLoad()

        infoView1.set(text: "Creating an owner key for your Safe Account...",
                      background: .clear,
                      status: .loading,
                      textStyle: .body)
        infoView2.set(text: "Securing it with your social login...",
                      background: .clear,
                      status: .loading,
                      textStyle: .body)
        infoView3.set(text: "Creating your Safe Account...",
                      background: .clear,
                      status: .loading,
                      textStyle: .body)
        titleLabel.setStyle(.title1)
        descriptionLabel.setStyle(.body)
        animationView.animation = LottieAnimation.named(isDarkMode ? "safeCreationDark" : "safeCreation",
                                                  animationCache: nil)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.play()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(accountCreated),
                                               name: .safeAccountOwnerCreated,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(accountSecured),
                                               name: .safeAccountOwnerSecured,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(safeSubmitted),
                                               name: .web3AuthSafeCreationUpdate,
                                               object: nil)
        onViewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.screenCreatingInProgress)
    }

    @objc func accountCreated() {
        infoView1.set(status: .success)
        // It is not defined, what this "owner secured" exactly means. Thats why we check this box after a short time automatically
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            NotificationCenter.default.post(name: .safeAccountOwnerSecured, object: nil)
        }
    }

    @objc func accountSecured() {
        infoView2.set(status: .success)
    }

    @objc func safeSubmitted() {
        infoView3.set(status: .success)
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] timer in
            DispatchQueue.main.async {
                self?.onSuccess()
            }
        }
    }
}

extension Notification.Name {
    static let safeAccountOwnerCreated = NSNotification.Name("io.gnosis.safe.safeAccountOwnerCreated")
    static let safeAccountOwnerSecured = NSNotification.Name("io.gnosis.safe.safeAccountOwner")
}
