//
//  RibbonView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 28.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class RibbonView: UINibView {

    var text: String? {
        get { label?.text }
        set { label?.text = newValue }
    }

    var textColor: UIColor? {
        get { label?.textColor }
        set { label?.textColor = newValue }
    }

    @IBOutlet private weak var label: GSLabel!

    override func commonInit() {
        super.commonInit()
        text = nil
        label.font = .systemFont(ofSize: 14, weight: .medium)
        heightConstraint = heightAnchor.constraint(equalToConstant: heightWhenHidden)
        heightConstraint.isActive = true
    }

    var network: Network?
    var heightConstraint: NSLayoutConstraint!
    let heightWhenVisible: CGFloat = 24
    let heightWhenHidden: CGFloat = 0

    func observeSelectedSafe() {
        NotificationCenter.default.removeObserver(self)

        let notifications: [Notification.Name] = [.selectedSafeChanged, .selectedSafeUpdated, .networkInfoChanged]
        for notificationName in notifications {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(updateFromSafe),
                name: notificationName,
                object: nil)
        }

        updateFromSafe()
    }

    @objc func updateFromSafe() {
        let safeOrNil = try? Safe.getSelected()
        update(network: safeOrNil?.network)
    }

    func update(network: Network?) {
        if let network = network,
           let name = network.chainName,
           let textColor = network.textColor,
           let backgroundColor = network.backgroundColor {
            // data
            self.text = name
            self.textColor = textColor
            self.backgroundColor = backgroundColor
            // show
            isHidden = false
            heightConstraint.constant = heightWhenVisible
            setNeedsUpdateConstraints()
        } else {
            // hide
            isHidden = true
            heightConstraint.constant = heightWhenHidden
            setNeedsUpdateConstraints()
        }
    }

}
