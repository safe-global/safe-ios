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
        var t = self
        t.color = newColor
        return t
    }

    func weight(_ value: UIFont.Weight) -> Self {
        var t = self
        t.weight = value
        return t
    }
}

extension GNOTextStyle {
    static let primary = GNOTextStyle(size: 17, weight: .medium, color: .primaryLabel)
    static let secondary = GNOTextStyle(size: 17, weight: .medium, color: .secondaryLabel)
    static let tertiary = GNOTextStyle(size: 17, weight: .medium, color: .tertiaryLabel)
    static let primaryError = GNOTextStyle(size: 17, weight: .medium, color: .error)
    static let primaryButton = GNOTextStyle(size: 17, weight: .medium, color: .button)

    static let caption1 = GNOTextStyle(size: 13, weight: .bold, letterSpacing: 2, color: .tertiaryLabel)
    static let caption2 = GNOTextStyle(size: 10, weight: .bold, letterSpacing: 2, color: .tertiaryLabel)
    static let caption3 = GNOTextStyle(size: 10, weight: .medium)

    static let footnote2 = GNOTextStyle(size: 13, weight: .medium, color: .secondaryLabel)
    static let footnote3 = GNOTextStyle(size: 13, weight: .medium, color: .primaryLabel)
    static let footnote4 = GNOTextStyle(size: 13, weight: .medium, color: .tertiaryLabel)

    static let subhead = GNOTextStyle(size: 15, weight: .bold)

    static let callout = GNOTextStyle(size: 16, weight: .regular, color: .primaryLabel)
    static let error = GNOTextStyle(size: 16, weight: .regular, color: .error)
    static let headline = GNOTextStyle(size: 17, weight: .semibold, color: .primaryLabel)
    static let headline2 = GNOTextStyle(size: 17, weight: .bold)

    static let title3 = GNOTextStyle(size: 20, weight: .regular, color: .primaryLabel)
    static let title4 = GNOTextStyle(size: 26, weight: .regular, color: .primaryLabel)
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

    func hyperLinkLabel(_ prefixText: String = "", prefixStyle: GNOTextStyle = .primary, linkText: String = "") {
        let result = NSMutableAttributedString()

        if !prefixText.isEmpty {
            let attributedText = NSMutableAttributedString(string: "\(prefixText) ", attributes: prefixStyle.attributes)
            result.append(attributedText)
        }

        // text + non-breaking space
        let attributedLinkText = NSMutableAttributedString(string: "\(linkText)\u{00A0}")
        attributedLinkText.addAttributes(GNOTextStyle.primaryButton.attributes, range: NSRange(location: 0, length: attributedLinkText.length))
        attributedLinkText.addAttributes([NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue], range: NSRange(location: 0, length: attributedLinkText.length))

        result.append(attributedLinkText)
        
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "icon-external-link")?.withTintColor(.button)
        let attachmentString = NSAttributedString(attachment: attachment)
        result.append(attachmentString)

        attributedText = result
    }
}

extension UITextField {
    func setStyle(_ style: GNOTextStyle) {
        font = .gnoFont(forTextStyle: style)
        textColor = style.color
    }
}

extension UITextView {
    func setStyle(_ style: GNOTextStyle) {
        font = .gnoFont(forTextStyle: style)
        textColor = style.color
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
    static let primary = GNOButtonStyle(appearance: [
        (.normal, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: UIColor.button,
            .font: UIFont.gnoFont(forTextStyle: .primary)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: UIColor.buttonPressed,
            .font: UIFont.gnoFont(forTextStyle: .primary)
        ])),
        (.disabled, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: UIColor.button.withAlphaComponent(0.5),
            .font: UIFont.gnoFont(forTextStyle: .primary)
        ]))
    ])

    static let plain = GNOButtonStyle(appearance: [
        (.normal, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: UIColor.button,
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: UIColor.buttonPressed,
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.disabled, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: UIColor.button.withAlphaComponent(0.5),
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ]))
    ])

    static let filled = GNOButtonStyle(appearance: [
        (.normal, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-filled-normal"), textAttributes: [
            .foregroundColor: UIColor.primaryBackground,
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-filled-pressed"), textAttributes: [
            .foregroundColor: UIColor.primaryBackground,
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.disabled, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-filled-inactive"), textAttributes: [
            .foregroundColor: UIColor.primaryBackground,
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ]))
    ])

    static let bordered = GNOButtonStyle(appearance: [
        (.normal, GNOButtonAppearance(backgroundImage: UIImage(named: "border-normal"), textAttributes: [
            .foregroundColor: UIColor.button,
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: UIImage(named: "border-normal"), textAttributes: [
            .foregroundColor: UIColor.button,
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.disabled, GNOButtonAppearance(backgroundImage: UIImage(named: "border-normal"), textAttributes: [
            .foregroundColor: UIColor.button,
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ]))
    ])

    static let filledError = GNOButtonStyle(appearance: [
        (.normal, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-error-filled-normal"), textAttributes: [
            .foregroundColor: UIColor.primaryBackground,
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-error-filled-pressed"), textAttributes: [
            .foregroundColor: UIColor.primaryBackground,
            .font: UIFont.gnoFont(forTextStyle: .headline2)
        ])),
        (.disabled, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-error-filled-inactive"), textAttributes: [
            .foregroundColor: UIColor.primaryBackground,
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
