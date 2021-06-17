//
//  GSLabel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class GSLabel: UILabel {
    var style: GNOTextStyle? {
        didSet {
            if let style = style {
                font = .gnoFont(forTextStyle: style)
                textColor = style.color
            } else {
                font = .systemFont(ofSize: UIFont.systemFontSize)
                textColor = .darkText
            }
        }
    }
}

