//
//  SafeTokenBanner.swift
//  Multisig
//
//  Created by Vitaly on 21.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeTokenBanner: UINibView {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var claimButton: UIButton!

    var onClaim: (() -> Void)?
    var onClose: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(hex: "#008C73")!.cgColor,
            UIColor(hex: "#008C8C")!.cgColor
        ]
        backgroundView.layer.addSublayer(gradientLayer)
        backgroundView.layer.cornerRadius = 8

        titleLabel.setStyle(.headline)
        titleLabel.textColor = .white
        messageLabel.setStyle(.callout)
        messageLabel.textColor = .primaryDisabled
        claimButton.titleLabel?.setStyle(.primary)
    }

    @IBAction func didTapClose(_ sender: Any) {
        onClose?()
    }

    @IBAction func didTapClaim(_ sender: Any) {
        onClaim?()
    }
}
