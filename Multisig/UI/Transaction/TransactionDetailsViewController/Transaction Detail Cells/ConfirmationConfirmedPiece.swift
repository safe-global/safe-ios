//
//  ConfirmationConfirmedPiece.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class ConfirmationConfirmedPiece: UINibView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressInfoView: AddressInfoView!
    @IBOutlet private weak var verticalBar: UIView!

    override func commonInit() {
        super.commonInit()
        titleLabel.setStyle(.headlinePrimary)
        // I wish the XIB would allow to set the height constraint to
        // the file owner, but it doesn't, so we set it in code here
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 88)
        ])
    }

    func setText(_ text: String) {
        titleLabel.text = text
    }

    func setShowsBar(_ shows: Bool) {
        verticalBar.isHidden = !shows
    }

    func setAddress(_ address: Address, label: String? = nil, badgeName: String? = nil, browseURL: URL?, prefix: String?) {
        addressInfoView.setAddress(address, label: label, badgeName: badgeName, browseURL: browseURL, prefix: prefix)
    }
}
