//
//  MiniAccountAndBalancePiece.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class MiniAccountAndBalancePiece: UINibView {
    @IBOutlet weak var addressInfoView: AddressInfoView!
    @IBOutlet weak var bottomLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        bottomLabel.setStyle(.caption1.weight(.medium))
        addressInfoView.setIconSize(24)
        addressInfoView.setCopyAddressEnabled(false)
    }

    func setModel(_ value: MiniAccountInfoUIModel) {
        addressInfoView.setAddressOneLine(
            value.address,
            label: value.label,
            imageUri: value.imageUri,
            badgeName: value.badge,
            prefix: value.prefix)

        bottomLabel.text = value.balance
    }
}
