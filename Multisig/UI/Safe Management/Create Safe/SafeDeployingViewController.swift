//
//  SafeDeployingViewController.swift
//  Multisig
//
//  Created by Moaaz on 2/24/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeDeployingViewController: UIViewController {

    @IBOutlet weak var desciptionLabel: UILabel!
    @IBOutlet weak var didYouKnowLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var txButton: UIButton!

    var safe: Safe?
    var containerViewYConstraint: NSLayoutConstraint?
    var txHash: String?

    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        desciptionLabel.setStyle(.secondary)
        didYouKnowLabel.setStyle(.primaryButton)
        statusLabel.setStyle(.headline2)
        txButton.setText("View transaction in block explorer", .primary)

        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .transactionDataInvalidated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .selectedSafeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .selectedSafeUpdated, object: nil)

        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(updateStatus), userInfo: nil, repeats: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
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
        updateStatus()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let safe = safe, safe.safeStatus == .deploymentFailed {
            DefaultNavigationRouter.shared.navigateAfterDelay(to: NavigationRoute.deploymentFailed(safe: safe))
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

    @objc func updateStatus() {
        statusLabel.pushTransition(0.5)
        statusLabel.text = statusName()
    }

    @IBAction func didTapViewTransaction(_ sender: Any) {
        if let txHash = txHash, let chain = safe?.chain {
            openInSafari(chain.browserURL(txHash: txHash))
        }
    }

    func statusName() -> String {
        guard let safe = safe else { return "" }
        switch safe.safeStatus {
        case .deploying:
            return "Deploying Smart Contract"
        case .indexing:
            return "Preparing your Safe"
        case .deployed:
            return "Safe is ready!"
        case .deploymentFailed:
            return "Failed to create Safe"
        }
    }
}

extension UIView {
    func pushTransition(_ duration: CFTimeInterval) {
        let animation:CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.push
        animation.duration = duration
        animation.subtype = .fromTop
        layer.add(animation, forKey: CATransitionType.push.rawValue)
    }
}
