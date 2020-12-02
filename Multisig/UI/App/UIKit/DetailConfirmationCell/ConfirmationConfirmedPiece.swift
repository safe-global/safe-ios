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
    @IBOutlet private weak var addressInfoView: UIView!
    @IBOutlet private weak var verticalBar: UIView!

    override func commonInit() {
        super.commonInit()
        titleLabel.setStyle(GNOTextStyle.body.color(.gnoHold))
        translatesAutoresizingMaskIntoConstraints = false
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

    func setAddressInfo(_ address: Address) {
        // TODO
    }
}
