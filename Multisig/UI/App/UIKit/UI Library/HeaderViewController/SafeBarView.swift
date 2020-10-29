//
//  SafeBarView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

/// When given:
///     - address, name: displays identicon, name, and address
///     - nothing: displays 'no safe loaded' icon and text
class SafeBarView: UINibView {
    @IBOutlet weak var identiconView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var button: UIButton!

    override func commonInit() {
        super.commonInit()
        textLabel.setStyle(.headline)
        detailLabel.setStyle(GNOTextStyle.body.color(.gnoMediumGrey))
    }

    func setAddress(_ value: Address) {
        identiconView.setAddress(value.hexadecimal)
        detailLabel.text = value.ellipsized()
    }

    func setName(_ value: String) {
        textLabel.text = value
    }
}
