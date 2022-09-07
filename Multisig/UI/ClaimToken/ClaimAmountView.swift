//
//  ClaimAmountView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.09.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ClaimAmountView: UINibView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var amountLabel: UILabel!

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var amount: String? {
        get { amountLabel.text }
        set { amountLabel.text = newValue }
    }

    var image: UIImage? {
        get { iconView.image }
        set { iconView.image = newValue }
    }

    override func commonInit() {
        super.commonInit()
        titleLabel.setStyle(.headline)
        amountLabel.setStyle(.title4.color(.labelSecondary))
    }
}
