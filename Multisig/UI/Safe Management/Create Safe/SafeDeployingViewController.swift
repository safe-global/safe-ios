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

    var safe: Safe?
    var containerViewYConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        safe = try? Safe.getSelected()
        assert(safe != nil)

        desciptionLabel.setStyle(.secondary)
        didYouKnowLabel.setStyle(.primaryButton)
        statusLabel.setStyle(.headline2)
        Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(updateStatus), userInfo: nil, repeats: true)

        NotificationCenter.default.addObserver(self, selector: #selector(updateStatus), name: .transactionDataInvalidated, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

    func statusName() -> String {
        guard let safeStatus = safe?.safeStatus else { return "" }
        switch safeStatus {
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
