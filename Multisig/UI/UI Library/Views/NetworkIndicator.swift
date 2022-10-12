//
//  NetworkIndicator.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 28.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class NetworkIndicator: UINibView {

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    var textStyle: GNOTextStyle? {
        get { label.style }
        set { label.style = newValue }
    }

    var dotColor: UIColor? {
        get { dotImageView.tintColor }
        set { dotImageView.tintColor = newValue }
    }

    var spacing: CGFloat {
        get { stackView.spacing }
        set { stackView.spacing = newValue }
    }

    @IBOutlet private var stackView: UIStackView!
    @IBOutlet private weak var dotImageView: UIImageView!
    @IBOutlet private weak var label: GSLabel!


    override func commonInit() {
        super.commonInit()
        text = nil
        dotColor = .clear
        textStyle = .footnote
    }
}
