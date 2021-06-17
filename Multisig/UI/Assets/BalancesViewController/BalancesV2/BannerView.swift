//
//  BannerView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class BannerView: UINibView {
    var headerText: String? {
        get { headerLabel?.text }
        set { headerLabel?.text = newValue }
    }
    var bodyText: String? {
        get { bodyLabel?.text }
        set { bodyLabel?.text = newValue }
    }
    var buttonText: String? {
        get { button.title(for: .normal) }
        set { button.setTitle(newValue, for: .normal) }
    }

    @IBOutlet private weak var headerLabel: GSLabel!
    @IBOutlet private weak var bodyLabel: GSLabel!
    @IBOutlet private weak var button: GSButton!

    override func commonInit() {
        super.commonInit()

        headerText = nil
        bodyText = nil
        buttonText = nil

        headerLabel.style = .headline
        bodyLabel.style = .primary
        button.style = .plain
    }
}
