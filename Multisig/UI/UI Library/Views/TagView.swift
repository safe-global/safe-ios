//
//  TagView.swift
//  Multisig
//
//  Created by Moaaz on 3/3/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class TagView: UINibView {
    @IBOutlet private var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!

    override func commonInit() {
        super.commonInit()
        titleLabel.setStyle(.footnote3)
        clipsToBounds = true
        layer.cornerRadius = 4
        backgroundColor = .backgroundTertiary
    }

    func set(title: String, style: GNOTextStyle = .footnote3, backgroundColor: UIColor = .backgroundTertiary, textColor: UIColor? = nil) {
        titleLabel.text = title
        titleLabel.setStyle(style)
        if textColor != nil {
            titleLabel.textColor = textColor
        }
        self.backgroundColor = backgroundColor
    }

    func setMargins(_ margins: NSDirectionalEdgeInsets) {
        containerView.directionalLayoutMargins = margins
        setNeedsLayout()
    }

}
