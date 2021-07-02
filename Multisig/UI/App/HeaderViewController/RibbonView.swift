//
//  RibbonView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 28.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class RibbonView: UINibView {

    var text: String? {
        get { label?.text }
        set { label?.text = newValue }
    }

    var textColor: UIColor? {
        get { label?.textColor }
        set { label?.textColor = newValue }
    }

    @IBOutlet private weak var label: GSLabel!

    override func commonInit() {
        super.commonInit()
        text = nil
        label.font = .systemFont(ofSize: 14, weight: .medium)
    }

}
