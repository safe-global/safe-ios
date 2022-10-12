//
//  GSButton.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class GSButton: UIButton {
    struct Style {
        var font: UIFont
        var config: [StateConfig]

        struct StateConfig {
            var state: UIControl.State
            var titleColor: UIColor?
            var backgroundImage: UIImage?
        }
    }

    var style: Style? {
        didSet {
            if let style = style {

                titleLabel?.font = style.font

                for config in style.config {
                    setTitleColor(config.titleColor, for: config.state)
                    setBackgroundImage(config.backgroundImage, for: config.state)
                }

            }
        }
    }
}

extension GSButton.Style {
    static let primary = GSButton.Style(
        font: .gnoFont(forTextStyle: .button),
        config: [
            StateConfig(state: .normal, titleColor: .primary, backgroundImage: nil),
            StateConfig(state: .highlighted, titleColor: .primaryPressed, backgroundImage: nil),
            StateConfig(state: .disabled, titleColor: .primary.withAlphaComponent(0.5), backgroundImage: nil)
        ]
    )

    static let plain = GSButton.Style(
        font: .gnoFont(forTextStyle: .button),
        config: [
            StateConfig(state: .normal, titleColor: .primary, backgroundImage: nil),
            StateConfig(state: .highlighted, titleColor: .primaryPressed, backgroundImage: nil),
            StateConfig(state: .disabled, titleColor: .primary.withAlphaComponent(0.5), backgroundImage: nil)
        ]
    )

    static let filled = GSButton.Style(
        font: .gnoFont(forTextStyle: .button),
        config: [
            StateConfig(state: .normal, titleColor: .backgroundPrimary, backgroundImage: UIImage(named: "btn-filled-normal")),
            StateConfig(state: .highlighted, titleColor: .backgroundPrimary, backgroundImage: UIImage(named: "btn-filled-pressed")),
            StateConfig(state: .disabled, titleColor: .backgroundPrimary, backgroundImage: UIImage(named: "btn-filled-inactive"))
        ]
    )

    static let filledError = GSButton.Style(
        font: .gnoFont(forTextStyle: .button),
        config: [
            StateConfig(state: .normal, titleColor: .backgroundPrimary, backgroundImage: UIImage(named: "btn-error-filled-normal")),
            StateConfig(state: .highlighted, titleColor: .backgroundPrimary, backgroundImage: UIImage(named: "btn-error-filled-pressed")),
            StateConfig(state: .disabled, titleColor: .backgroundPrimary, backgroundImage: UIImage(named: "btn-error-filled-inactive"))
        ]
    )
}
