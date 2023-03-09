//
//  RelayInfoBanner.swift
//  Multisig
//
//  Created by Vitaly on 04.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class RelayInfoBanner: UINibView {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var bannerButton: UIButton!
    @IBOutlet private weak var closeButton: UIButton!

    var onOpen: (() -> Void)?
    var onClose: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        overrideUserInterfaceStyle = .light
        clipsToBounds = true
        layer.cornerRadius = 8
        titleLabel.setStyle(.headline)
        messageLabel.setStyle(.callout)
    }

    @IBAction func didTapBanner(_ sender: Any) {
        onOpen?()
    }

    @IBAction func didTapClose(_ sender: Any) {
        onClose?()
    }
}
