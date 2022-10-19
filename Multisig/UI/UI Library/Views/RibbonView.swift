//
//  RibbonView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 28.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

/// Ribbon to show the network name. Hidden by default.
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

    private var heightConstraint: NSLayoutConstraint!
    private let heightWhenVisible: CGFloat = 24
    private let heightWhenHidden: CGFloat = 0

    override func commonInit() {
        super.commonInit()
        text = nil
        label.font = UIFont.gnoFont(forTextStyle: .footnote)
        heightConstraint = heightAnchor.constraint(equalToConstant: heightWhenHidden)
        heightConstraint.isActive = true
    }

    /// Displays the ribbon
    func show() {
        isHidden = false
        heightConstraint.constant = heightWhenVisible
        setNeedsUpdateConstraints()
    }

    /// Hides the ribbon
    func hide() {
        isHidden = true
        heightConstraint.constant = heightWhenHidden
        setNeedsUpdateConstraints()
    }

    /// Updates the ribbon from currently selected safe's network and observes changes to the safe and network info
    func observeSelectedSafe() {
        NotificationCenter.default.removeObserver(self)

        let notifications: [Notification.Name] = [.selectedSafeChanged, .selectedSafeUpdated, .chainInfoChanged]
        for notificationName in notifications {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(updateFromSafe),
                name: notificationName,
                object: nil)
        }

        updateFromSafe()
    }

    /// Updates ribbon UI based on safe's network
    @objc func updateFromSafe() {
        let safeOrNil = try? Safe.getSelected()
        update(chain: safeOrNil?.chain)
    }

    /// Updates ribbon UI based on the network
    /// - Parameter network: The network data. If nil, the ribbon will hide. If not nil, it will be shown.
    func update(chain: Chain?) {
        if let chain = chain,
           let name = chain.name,
           let textColor = chain.textColor,
           let backgroundColor = chain.backgroundColor {
            self.text = name
            self.textColor = textColor
            self.backgroundColor = backgroundColor
            show()
        } else {
            hide()
        }
    }

    func update(scgChain: SCGModels.Chain?) {
        if let chain = scgChain,
           let textColor = UIColor(hex: chain.theme.textColor),
           let backgroundColor = UIColor(hex: chain.theme.backgroundColor) {
            self.text = chain.chainName
            self.textColor = textColor
            self.backgroundColor = backgroundColor
            show()
        } else {
            hide()
        }
    }

}
