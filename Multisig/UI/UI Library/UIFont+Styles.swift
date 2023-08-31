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
    var familyName: String? = "DMSans"
    var fullFontName: String? {
        familyName == nil ? nil : [familyName!, weight.name].joined(separator: "-")
    }

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

    func size(_ value: CGFloat) -> Self {
        var t = self
        t.size = value
        return t
    }
}

extension GNOTextStyle {
    static let slogan = GNOTextStyle(size: 28, weight: .semibold, color: .labelPrimary)
    // Heading
    static let largeTitle = GNOTextStyle(size: 33, weight: .bold, color: .labelPrimary)
    static let title1 = GNOTextStyle(size: 28, weight: .bold, color: .labelPrimary)
    static let title1Medium = GNOTextStyle(size: 28, weight: .medium, color: .labelPrimary)
    static let title2 = GNOTextStyle(size: 22, weight: .bold, color: .labelPrimary)
    static let title3 = GNOTextStyle(size: 20, weight: .medium, color: .labelPrimary)
    static let title3Secondary = GNOTextStyle(size: 20, weight: .medium, color: .labelSecondary)
    static let headline = GNOTextStyle(size: 17, weight: .medium, color: .labelPrimary)
    static let headlinePrimary = GNOTextStyle(size: 17, weight: .medium, color: .primary)
    static let headlinePrimaryInverted = GNOTextStyle(size: 17, weight: .medium, color: .primaryInverted)

    static let headlineSuccess = GNOTextStyle(size: 17, weight: .medium, color: .success)
    static let headlineBaseSuccess = GNOTextStyle(size: 17, weight: .medium, color: .baseSuccess)
    static let headlineError = GNOTextStyle(size: 17, weight: .medium, color: .error)
    static let headlineSecondary = GNOTextStyle(size: 17, weight: .medium, color: .labelSecondary)

    // Paragraph
    static let body = GNOTextStyle(size: 17, weight: .regular, color: .labelSecondary)
    static let bodyPrimary = GNOTextStyle(size: 17, weight: .regular, color: .labelPrimary)
    static let bodyTertiary = GNOTextStyle(size: 17, weight: .regular, color: .labelTertiary)
    static let bodyError = GNOTextStyle(size: 17, weight: .regular, color: .error)
    static let bodyMedium = GNOTextStyle(size: 17, weight: .medium, color: .labelSecondary)
    static let callout = GNOTextStyle(size: 16, weight: .regular, color: .labelSecondary)
    static let calloutError = GNOTextStyle(size: 16, weight: .regular, color: .error)
    static let calloutTertiary = GNOTextStyle(size: 16, weight: .regular, color: .labelTertiary)
    static let calloutPrimary = GNOTextStyle(size: 16, weight: .regular, color: .labelPrimary)
    static let calloutMedium = GNOTextStyle(size: 16, weight: .medium, color: .labelSecondary)
    static let calloutMediumPrimary = GNOTextStyle(size: 16, weight: .medium, color: .labelPrimary)
    static let calloutMediumError = GNOTextStyle(size: 16, weight: .medium, color: .error)

    // Label
    static let subheadline = GNOTextStyle(size: 15, weight: .regular, color: .labelPrimary)
    static let subheadlineSecondary = GNOTextStyle(size: 15, weight: .regular, color: .labelSecondary)
    static let subheadline1Medium = GNOTextStyle(size: 15, weight: .medium, color: .labelPrimary)
    static let subheadlineMediumTertiary = GNOTextStyle(size: 15, weight: .medium, color: .labelTertiary)
    static let subheadlineMediumError = GNOTextStyle(size: 15, weight: .medium, color: .error)
    static let subheadlineMediumWaring = GNOTextStyle(size: 15, weight: .medium, color: .warning)
    static let subheadlineMediumSuccess = GNOTextStyle(size: 15, weight: .medium, color: .success)
    static let caption1 = GNOTextStyle(size: 12, weight: .regular, color: .labelSecondary)
    static let caption1Medium = GNOTextStyle(size: 12, weight: .medium, color: .labelSecondary)
    static let caption2 = GNOTextStyle(size: 12, weight: .bold, color: .labelPrimary)
    static let caption2Tertiary = GNOTextStyle(size: 12, weight: .bold, color: .labelTertiary)
    static let caption2Secondary = GNOTextStyle(size: 12, weight: .bold, color: .labelSecondary)

    static let footnote = GNOTextStyle(size: 13, weight: .medium, color: .labelTertiary)
    static let footnoteSecondary = GNOTextStyle(size: 13, weight: .medium, color: .labelSecondary)
    static let footnotePrimary = GNOTextStyle(size: 13, weight: .medium, color: .labelPrimary)
    static let button = GNOTextStyle(size: 17, weight: .medium, color: .labelPrimary)
    static let buttonSmall = GNOTextStyle(size: 15, weight: .medium, color: .labelPrimary)
    static let buttonLight = GNOTextStyle(size: 17, weight: .medium, color: .backgroundSecondary)

    // Custom
    static let tabBarTitle = GNOTextStyle(size: 11, weight: .medium, color: .labelTertiary)
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
        if let customFontName = style.fullFontName, let font = UIFont(name: customFontName, size: style.size) {
            return font
        } else {
            return .systemFont(ofSize: style.size, weight: style.weight)
        }
    }
}

extension UIFont.Weight {
    var name: String {
        switch self {
        case .bold: return "Bold"
        case .medium: return "Medium"
        case .regular: return "Regular"
        case .thin: return "Thin"
        case .light: return "Light"
        case .semibold: return "Semibold"
        case .black: return "Black"
        case .heavy: return "Heavy"
        case .ultraLight: return "UltraLight"
        default: return "Regular"
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

    func hyperLinkLabel(_ prefixText: String = "",
                        prefixStyle: GNOTextStyle = .button,
                        linkText: String = "",
                        linkStyle: GNOTextStyle = .headline.color(.primary),
                        linkIcon: UIImage? = UIImage(named: "icon-external-link")!.withTintColor(.primary),
                        underlined: Bool = true,
                        postfixText: String = "") {
        let result = NSMutableAttributedString()

        if !prefixText.isEmpty {
            let attributedText = NSMutableAttributedString(string: "\(prefixText) ", attributes: prefixStyle.attributes)
            result.append(attributedText)
        }

        // text + non-breaking space
        let attributedLinkText = NSMutableAttributedString(string: "\(linkText)")
        attributedLinkText.addAttributes(linkStyle.attributes, range: NSRange(location: 0, length: attributedLinkText.length))
        if underlined {
            attributedLinkText.addAttributes([NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue], range: NSRange(location: 0, length: attributedLinkText.length))
        }

        result.append(attributedLinkText)

        if let icon = linkIcon {
            result.append(NSMutableAttributedString(string: "\u{00A0}"))
            let attachment = NSTextAttachment(image: icon.withTintColor(.primary))
            // for some reason the image sticks to the 'top' of the line, so we have to offset it vertically
            let lineHeight = UIFont.gnoFont(forTextStyle: linkStyle).lineHeight
            let verticalOffset = (icon.size.height - lineHeight) / 2
            attachment.bounds = CGRect(x: 0, y: verticalOffset, width: icon.size.width, height: icon.size.height)
            let attachmentString = NSAttributedString(attachment: attachment)
            result.append(attachmentString)
        }

        let attributedWithPostfix = NSMutableAttributedString(string: postfixText, attributes: prefixStyle.attributes)
        result.append(attributedWithPostfix)

        attributedText = result
    }

    func apendBetaBadge() {
        let result = NSMutableAttributedString()
        if attributedText?.length ?? 0 > 0 {
            result.append(attributedText!)
            result.append(NSAttributedString(string: " "))
        }
        let betaSymbol = NSTextAttachment()
        betaSymbol.image = UIImage(named: "ico-beta")
        betaSymbol.bounds = CGRectMake(0.0, -6.0, betaSymbol.image!.size.width, betaSymbol.image!.size.height)
        let betaSymbolString = NSAttributedString(attachment: betaSymbol)
        result.append(betaSymbolString)
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
            .foregroundColor: UIColor.primary,
            .font: UIFont.gnoFont(forTextStyle: .buttonLight)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: UIColor.primaryPressed,
            .font: UIFont.gnoFont(forTextStyle: .buttonLight)
        ])),
        (.disabled, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: UIColor.primary.withAlphaComponent(0.5),
            .font: UIFont.gnoFont(forTextStyle: .buttonLight)
        ]))
    ])

    static let plain = GNOButtonStyle(appearance: [
        (.normal, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: UIColor.primary,
            .font: UIFont.gnoFont(forTextStyle: .button)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: UIColor.primaryPressed,
            .font: UIFont.gnoFont(forTextStyle: .button)
        ])),
        (.disabled, GNOButtonAppearance(backgroundImage: nil, textAttributes: [
            .foregroundColor: UIColor.primary.withAlphaComponent(0.5),
            .font: UIFont.gnoFont(forTextStyle: .button)
        ]))
    ])

    static let filled = GNOButtonStyle(appearance: [
        (.normal, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-filled-normal"), textAttributes: [
            .foregroundColor: UIColor.backgroundPrimary,
            .font: UIFont.gnoFont(forTextStyle: .button)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-filled-pressed"), textAttributes: [
            .foregroundColor: UIColor.backgroundPrimary,
            .font: UIFont.gnoFont(forTextStyle: .button)
        ])),
        (.disabled, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-filled-inactive"), textAttributes: [
            .foregroundColor: UIColor.labelTertiary,
            .font: UIFont.gnoFont(forTextStyle: .button)
        ]))
    ])

    static let bordered = GNOButtonStyle(appearance: [
        (.normal, GNOButtonAppearance(backgroundImage: UIImage(named: "border-normal")?.withTintColor(.primary), textAttributes: [
            .foregroundColor: UIColor.primary,
            .font: UIFont.gnoFont(forTextStyle: .button)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: UIImage(named: "border-normal")?.withTintColor(.primary), textAttributes: [
            .foregroundColor: UIColor.primary,
            .font: UIFont.gnoFont(forTextStyle: .button)
        ])),
        (.disabled, GNOButtonAppearance(backgroundImage: UIImage(named: "border-normal")?.withTintColor(.primary), textAttributes: [
            .foregroundColor: UIColor.primary,
            .font: UIFont.gnoFont(forTextStyle: .button)
        ]))
    ])

    static let filledError = GNOButtonStyle(appearance: [
        (.normal, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-error-filled-normal"), textAttributes: [
            .foregroundColor: UIColor.error,
            .font: UIFont.gnoFont(forTextStyle: .button)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-error-filled-pressed"), textAttributes: [
            .foregroundColor: UIColor.error,
            .font: UIFont.gnoFont(forTextStyle: .button)
        ])),
        (.disabled, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-error-filled-inactive"), textAttributes: [
            .foregroundColor: UIColor.error,
            .font: UIFont.gnoFont(forTextStyle: .button)
        ]))
    ])

    static let tweet = GNOButtonStyle(appearance: [
        (.normal, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-tweet-normal"), textAttributes: [
            .foregroundColor: UIColor.white,
            .font: UIFont.gnoFont(forTextStyle: .button)
        ])),
        (.highlighted, GNOButtonAppearance(backgroundImage: UIImage(named: "btn-tweet-pressed"), textAttributes: [
            .foregroundColor: UIColor.white,
            .font: UIFont.gnoFont(forTextStyle: .button)
        ]))
    ])
}

extension UIButton {
    func setText(_ text: String?, _ style: GNOButtonStyle) {
        for (state, appearance) in style.appearance {
            setAttributedTitle(text.map { appearance.attributedString($0) }, for: state)
            setBackgroundImage(appearance.backgroundImage, for: state)
        }
    }
}
