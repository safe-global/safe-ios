//
//  UIColor+Styles.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 29.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UIColor {
    static let button = UIColor(named: "button")!
    static let buttonPressed = UIColor(named: "buttonPressed")!
    static let cardShadowTooltip = UIColor(named: "cardShadowTooltip")!
    static let error = UIColor(named: "error")!
    static let errorPressed = UIColor(named: "errorPressed")!
    static let rejection = UIColor(named: "rejection")!
    static let gray2 = UIColor(named: "gray2")!
    static let gray4 = UIColor(named: "gray4")!
    static let gray5 = UIColor(named: "gray5")!
    static let pending = UIColor(named: "pending")!
    static let primaryBackground = UIColor(named: "primaryBackground")!
    static let primaryLabel = UIColor(named: "primaryLabel")!
    static let secondaryBackground = UIColor(named: "secondaryBackground")!
    static let secondaryLabel = UIColor(named: "secondaryLabel")!
    static let separator = UIColor(named: "separator")!
    static let shadow = UIColor(named: "shadow")!
    static let tertiaryBackground = UIColor(named: "tertiaryBackground")!
    static let tertiaryLabel = UIColor(named: "tertiaryLabel")!
    static let quaternaryBackground = UIColor(named: "quaternaryBackground")!
}

extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}



