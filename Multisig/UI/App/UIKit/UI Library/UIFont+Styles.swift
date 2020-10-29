//
//  UIFont+Styles.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 29.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

struct GNOTextStyle: Hashable {
    var size: CGFloat
    var weight: UIFont.Weight
    var fontName: String?
    var color: UIColor?

    func color(_ newColor: UIColor?) -> Self {
        guard let newColor = newColor else { return self }
        return .init(size: size, weight: weight, fontName: fontName, color: newColor)
    }
}

extension GNOTextStyle {
    static let caption3 = GNOTextStyle(size: 10, weight: .medium)
    static let caption2 = GNOTextStyle(size: 10, weight: .bold)

    static let footnote2 = GNOTextStyle(size: 13, weight: .medium, color: #colorLiteral(red: 0.3647058824, green: 0.4274509804, blue: 0.4549019608, alpha: 1))
    static let caption1 = GNOTextStyle(size: 13, weight: .bold)

    static let subhead = GNOTextStyle(size: 15, weight: .bold)

    static let callout = GNOTextStyle(size: 16, weight: .regular)

    static let body = GNOTextStyle(size: 17, weight: .medium, color: #colorLiteral(red: 0, green: 0.07843137255, blue: 0.1568627451, alpha: 1))
    static let headline = GNOTextStyle(size: 17, weight: .semibold, color: #colorLiteral(red: 0, green: 0.07843137255, blue: 0.1568627451, alpha: 1))
    static let headline2 = GNOTextStyle(size: 17, weight: .bold)

    static let title3 = GNOTextStyle(size: 20, weight: .regular, color: #colorLiteral(red: 0, green: 0.07843137255, blue: 0.1568627451, alpha: 1))

    static let normal = GNOTextStyle(size: 26, weight: .regular, fontName: "Averta Regular")

}

extension UIFont {
    static func gnoFont(forTextStyle style: GNOTextStyle) -> UIFont {
        if let customFontName = style.fontName {
            let descriptor = UIFontDescriptor(name: customFontName, size: style.size)
            return UIFont(descriptor: descriptor, size: style.size)
        } else {
            return .systemFont(ofSize: style.size, weight: style.weight)
        }
    }
}

extension UILabel {
    func setStyle(_ style: GNOTextStyle) {
        font = .gnoFont(forTextStyle: style)
        textColor = style.color
    }
}
