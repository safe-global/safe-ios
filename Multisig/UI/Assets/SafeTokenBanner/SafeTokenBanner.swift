//
//  SafeTokenBanner.swift
//  Multisig
//
//  Created by Vitaly on 21.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeTokenBanner: UINibView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var claimButton: UIButton!

    var onClaim: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(hex: "#008C73")!.cgColor,
            UIColor(hex: "#008C8C")!.cgColor
        ]
        layer.addSublayer(gradientLayer)
        layer.cornerRadius = 8
        clipsToBounds = true
        titleLabel.setStyle(.headline)
        titleLabel.textColor = .primaryDisabled
        messageLabel.setStyle(.callout)
        messageLabel.textColor = .primaryDisabled
        claimButton.titleLabel?.setStyle(.primary)
        claimButton.setTitleColor(.black, for: .normal)
    }

    @IBAction func didTapClaim(_ sender: Any) {
        onClaim?()
    }
}
