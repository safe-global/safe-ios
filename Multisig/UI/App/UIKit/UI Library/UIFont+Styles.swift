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
    var letterSpacing: Double?
    var color: UIColor?

    func color(_ newColor: UIColor?) -> Self {
        guard let newColor = newColor else { return self }
        return .init(size: size, weight: weight, fontName: fontName, letterSpacing: letterSpacing, color: newColor)
    }
}

extension GNOTextStyle {
    static let caption3 = GNOTextStyle(size: 10, weight: .medium)
    static let caption2 = GNOTextStyle(size: 10, weight: .bold, letterSpacing: 2, color: .gnoMediumGrey)

    static let footnote2 = GNOTextStyle(size: 13, weight: .medium, color: .gnoDarkGrey)
    static let footnote3 = GNOTextStyle(size: 13, weight: .medium, color: .gnoDarkBlue)
    static let caption1 = GNOTextStyle(size: 13, weight: .bold)

    static let subhead = GNOTextStyle(size: 15, weight: .bold)

    static let callout = GNOTextStyle(size: 16, weight: .regular)

    static let body = GNOTextStyle(size: 17, weight: .medium, color: .gnoDarkBlue)
    static let headline = GNOTextStyle(size: 17, weight: .semibold, color: .gnoDarkBlue)
    static let headline2 = GNOTextStyle(size: 17, weight: .bold)

    static let title3 = GNOTextStyle(size: 20, weight: .regular, color: .gnoDarkBlue)

    static let normal = GNOTextStyle(size: 26, weight: .regular, fontName: "Averta Regular")
}

extension GNOTextStyle {
    var attributes: [NSAttributedString.Key: Any] {
        var result = [NSAttributedString.Key: Any]()
        result[.font] = UIFont.gnoFont(forTextStyle: self)
        if let color = color {
            result[.foregroundColor] = color
        }
        if let kern = letterSpacing {
            result[.kern] = NSNumber(value: kern)
        }
        return result
    }
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

    func setAttributedText(_ text: String, style: GNOTextStyle) {
        attributedText = NSAttributedString(string: text, attributes: style.attributes)
    }
}

struct GNOButtonAppearance {
    var backgroundImage: UIImage?
    var textAttributes: [NSAttributedString.Key: Any] = [:]

    func attributedString(_ text: String) -> NSAttributedString {
        .init(string: text, attributes: textAttributes)
    }
}

struct GNOButtonStyle {
    var appearance: [(state: UIControl.State, value: GNOButtonAppearance)] = []

    func font(_ newFont: UIFont) -> Self {
        var result = self
        for index in (0..<result.appearance.count) {
            var newAppearance = result.appearance[index].value
            newAppearance.textAttributes[.font] = newFont
            result.appearance[index] = (result.appearance[index].state, newAppearance)
        }
        return result
    }
}

extension GNOButtonStyle {
    static let plain = GNOButtonStyle(appearance: [
        (.normal, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: #colorLiteral(red: 0, green: 0.5490000248, blue: 0.451000005, alpha: 1),
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: #colorLiteral(red: 0, green: 0.3333333333, blue: 0.2745098039, alpha: 1),
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.disabled, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: #colorLiteral(red: 0, green: 0.5490000248, blue: 0.451000005, alpha: 0.5),
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ]))
    ])

    static let bordered = GNOButtonStyle(appearance: [
        (.normal, GNOButtonAppearance(backgroundImage: #imageLiteral(resourceName: "btn-bordered-normal"), textAttributes: [
            .foregroundColor: #colorLiteral(red: 0, green: 0.07843137255, blue: 0.1568627451, alpha: 1),
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: #imageLiteral(resourceName: "btn-bordered-pressed"), textAttributes: [
            .foregroundColor: #colorLiteral(red: 0, green: 0.07843137255, blue: 0.1568627451, alpha: 1).withAlphaComponent(0.7),
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.disabled, GNOButtonAppearance(backgroundImage: #imageLiteral(resourceName: "btn-bordered-inactive"), textAttributes: [
            .foregroundColor: #colorLiteral(red: 0, green: 0.07843137255, blue: 0.1568627451, alpha: 1).withAlphaComponent(0.5),
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ]))
    ])

    static let filled = GNOButtonStyle(appearance: [
        (.normal, GNOButtonAppearance(backgroundImage: #imageLiteral(resourceName: "btn-filled-normal"), textAttributes: [
            .foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: #imageLiteral(resourceName: "btn-filled-pressed"), textAttributes: [
            .foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.disabled, GNOButtonAppearance(backgroundImage: #imageLiteral(resourceName: "btn-filled-inactive"), textAttributes: [
            .foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ]))
    ])
}

extension UIButton {
    func setText(_ text: String, _ style: GNOButtonStyle) {
        for (state, appearance) in style.appearance {
            setAttributedTitle(appearance.attributedString(text), for: state)
            setBackgroundImage(appearance.backgroundImage, for: state)
        }
    }
}
