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
                .foregroundColor, value: UIColor.labelPrimary, range: NSRange(location: 0, length: count))
        } else {
            attributedString.addAttribute(
                .foregroundColor, value: UIColor.labelPrimary, range: NSRange(location: 0, length: prefix))
            attributedString.addAttribute(
                .foregroundColor, value: UIColor.labelPrimary, range: NSRange(location: count - suffix, length: suffix))
        }
        
        return attributedString
    }

    func highlightRange(originalStyle: GNOTextStyle = .secondary,
                        highlightStyle: GNOTextStyle = .primary,
                        textToHightlight: String? = nil) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(
            string: self,
            attributes: [
                .font: UIFont.gnoFont(forTextStyle: originalStyle),
                .foregroundColor: originalStyle.color!,
                .kern: -0.41
            ]
        )

        if let textToHightlight = textToHightlight {
            let rangeToHightlight = (attributedString.string as NSString).range(of: textToHightlight)
            attributedString.addAttributes([
                .font: UIFont.gnoFont(forTextStyle: highlightStyle),
                .foregroundColor: highlightStyle.color ?? .labelPrimary],
                range: rangeToHightlight)
        }

        return attributedString
    }
}
