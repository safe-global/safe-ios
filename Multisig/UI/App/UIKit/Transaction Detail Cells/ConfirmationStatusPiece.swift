//
//  ConfirmationStatusPiece.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class ConfirmationStatusPiece: UINibView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!

    override func commonInit() {
        super.commonInit()
        titleLabel.setStyle(.body)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    func setText(_ text: String, style: GNOTextStyle) {
        titleLabel.setStyle(style)
        titleLabel.text = text
    }

    func setSymbol(_ name: String, color: UIColor) {
        iconImageView.image = UIImage(systemName: name)?.applyingSymbolConfiguration(.init(weight: .bold))
        iconImageView.tintColor = color
    }
}
