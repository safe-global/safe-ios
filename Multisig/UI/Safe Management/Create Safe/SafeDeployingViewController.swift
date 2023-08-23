//
//  SafeDeployingViewController.swift
//  Multisig
//
//  Created by Moaaz on 2/24/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import Lottie

class SafeDeployingViewController: UIViewController {

    @IBOutlet weak var desciptionLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var txButton: UIButton!
    @IBOutlet weak var animationView: LottieAnimationView!

    var safe: Safe?
    var containerViewYConstraint: NSLayoutConstraint?
    var txHash: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        statusLabel.setStyle(.title3)
        desciptionLabel.setStyle(.body)
        txButton.setText("View transaction in block explorer", .primary)

        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .transactionDataInvalidated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .selectedSafeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .selectedSafeUpdated, object: nil)

        animationView.animation = LottieAnimation.named(isDarkMode ? "safeCreationDark" : "safeCreation", animationCache: nil)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.play()

        reloadData()
    }

    @objc func reloadData() {
        guard let safe = try? Safe.getSelected() else {
            self.safe = nil
            return
        }
        self.safe = safe

        if safe.safeStatus == .deploying || safe.safeStatus == .indexing {
            if let call = SafeCreationCall.by(safe: safe).first {
                self.txHash = call.transactionHash
            } else if let tx = CDEthTransaction.by(safeAddresses: [safe.addressValue.checksummed], chainId: safe.chain!.id!).first {
                self.txHash = tx.ethTxHash
            }
        }

        txButton.isHidden = txHash == nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animationView.play()
        if let safe = safe, safe.safeStatus == .deploymentFailed {
            CompositeNavigationRouter.shared.navigateAfterDelay(to: NavigationRoute.deploymentFailed(safe: safe))
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // center the text relative to the window instead of containing view
        // because this screen is used several times in different tabs
        // and the Y position of this view will be different -> leading to
        // the visual jumps when switching the tabs.
        if let window = view.window, containerViewYConstraint == nil || containerViewYConstraint?.isActive == false {
            containerViewYConstraint = containerView.centerYAnchor.constraint(equalTo: window.centerYAnchor)
            containerViewYConstraint?.isActive = true
            view.setNeedsLayout()
        }
    }

    @IBAction func didTapViewTransaction(_ sender: Any) {
        Tracker.trackEvent(.createSafeViewTxOnEtherscan)
        if let txHash = txHash, let chain = safe?.chain {
            openInSafari(chain.browserURL(txHash: txHash))
        }
    }
}
