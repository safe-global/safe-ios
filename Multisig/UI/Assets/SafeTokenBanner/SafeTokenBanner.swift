//
//  SafeTokenBanner.swift
//  Multisig
//
//  Created by Vitaly on 21.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeTokenBanner: UINibView {

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var claimButton: UIButton!

    var onClaim: (() -> Void)?
    var onClose: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
        layer.cornerRadius = 8
        titleLabel.setStyle(.headline)
        titleLabel.textColor = .primaryDisabled
        messageLabel.setStyle(.callout)
        messageLabel.textColor = .primaryDisabled
        claimButton.titleLabel?.setStyle(.primary)
        claimButton.setTitleColor(.black, for: .normal)
    }

    @IBAction func didTapClose(_ sender: Any) {
        onClose?()
        claimButton.setTitleColor(.black, for: .normal)
    }

    @IBAction func didTapClaim(_ sender: Any) {
        onClaim?()
    }
}
