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
        titleLabel.setStyle(.caption1)
        clipsToBounds = true
        layer.cornerRadius = 3
        backgroundColor = .backgroundPrimary
    }

    func set(title: String, style: GNOTextStyle = .caption1, backgroundColor: UIColor = .backgroundPrimary, textColor: UIColor? = nil) {
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
