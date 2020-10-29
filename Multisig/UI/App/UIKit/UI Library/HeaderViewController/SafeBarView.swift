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
    @IBOutlet weak var identiconView: IdenticonView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var button: UIButton!

    func setAddress(_ value: String) {
        identiconView.setAddress(value)
        detailLabel.text = value
    }

    func setName(_ value: String) {
        textLabel.text = value
    }
}
