//
//  Address+Extensions.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 26.07.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

extension Address {
    var highlighted: NSAttributedString {
        let style = GNOTextStyle.tertiary
        let attributedString = NSMutableAttributedString(
            string: checksummed,
            attributes: [
                .font: UIFont.gnoFont(forTextStyle: style),
                .foregroundColor: style.color!,
                .kern: -0.41
            ]
        )
        attributedString.addAttribute(
            .foregroundColor, value: UIColor.primaryLabel, range: NSRange(location: 0, length: 4))
        attributedString.addAttribute(
            .foregroundColor, value: UIColor.primaryLabel, range: NSRange(location: 38, length: 4))
        return attributedString
    }
}
