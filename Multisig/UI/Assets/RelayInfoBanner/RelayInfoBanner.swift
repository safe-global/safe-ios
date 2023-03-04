//
//  RelayInfoBanner.swift
//  Multisig
//
//  Created by Vitaly on 04.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class RelayInfoBanner: UINibView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!

    var onClose: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        overrideUserInterfaceStyle = .light
        clipsToBounds = true
        layer.cornerRadius = 8
        titleLabel.setStyle(.headline)
        messageLabel.setStyle(.callout)
    }

    @IBAction func didTapClose(_ sender: Any) {
        onClose?()
    }
}
