//
//  HashString+UIKit.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

extension HashString {
    var highlighted: NSAttributedString {
        let style = GNOTextStyle.tertiary
        let attributedString = NSMutableAttributedString(
            string: description,
            attributes: [
                .font: UIFont.gnoFont(forTextStyle: style),
                .foregroundColor: style.color!,
                .kern: -0.41
            ]
        )
        attributedString.addAttribute(
            .foregroundColor, value: UIColor.primaryLabel, range: NSRange(location: 0, length: 6))
        attributedString.addAttribute(
            .foregroundColor, value: UIColor.primaryLabel, range: NSRange(location: description.count - 4, length: 4))
        return attributedString
    }
}
