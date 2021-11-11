//
//  String+Highlight.swift
//  Multisig
//
//  Created by Moaaz on 11/10/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func highlight(prefix: Int = 6, suffix: Int = 4) -> NSAttributedString {
        let style = GNOTextStyle.tertiary
        let attributedString = NSMutableAttributedString(
            string: self,
            attributes: [
                .font: UIFont.gnoFont(forTextStyle: style),
                .foregroundColor: style.color!,
                .kern: -0.41
            ]
        )

        if self.count < prefix + suffix {
            attributedString.addAttribute(
                .foregroundColor, value: UIColor.primaryLabel, range: NSRange(location: 0, length: count))
        } else {
            attributedString.addAttribute(
                .foregroundColor, value: UIColor.primaryLabel, range: NSRange(location: 0, length: prefix))
            attributedString.addAttribute(
                .foregroundColor, value: UIColor.primaryLabel, range: NSRange(location: count - suffix, length: suffix))
        }
        
        return attributedString
    }
}
