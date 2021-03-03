//
//  TagView.swift
//  Multisig
//
//  Created by Moaaz on 3/3/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class TagView: UINibView {
    @IBOutlet private weak var titleLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        titleLabel.setStyle(.footnote3)
        clipsToBounds = true
        layer.cornerRadius = 4
    }

    func set(title: String) {
        titleLabel.text = title
    }
}
