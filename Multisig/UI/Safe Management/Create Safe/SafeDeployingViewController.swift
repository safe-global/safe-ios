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

    var x = 0
    var safe: Safe?
    var containerViewYConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        desciptionLabel.setStyle(.secondary)
        didYouKnowLabel.setStyle(.primaryButton)
        statusLabel.setStyle(.headline2)
        Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(updateStatus), userInfo: nil, repeats: true)
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

        self.x = self.x + 1
    }

    func statusName() -> String {
        if x == 0 {
            return "Transaction submitted"
        } else if x == 1 {
            return "Validating transaction"
        } else if x == 2 {
            return "Deploying Smart Contract"
        } else if x == 3 {
            return "Generating your Safe"
        }

        return ""
    }
}

extension UIView {
    func pushTransition(_ duration: CFTimeInterval) {
        let animation:CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.push //1.
        animation.duration = duration
        animation.subtype = .fromTop
        layer.add(animation, forKey: CATransitionType.push.rawValue)//2.
    }
}
