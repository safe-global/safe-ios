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
    convenience init?(hex: String) {
        guard hex.hasPrefix("#") else { return nil }
        var string = hex
        string.removeFirst()

        // rgb -> rr gg bb
        if string.count == 3 {
            string =
                // rr
                String(repeating: string[string.index(string.startIndex, offsetBy: 0)], count: 2) +
                // gg
                String(repeating: string[string.index(string.startIndex, offsetBy: 1)], count: 2) +
                // bb
                String(repeating: string[string.index(string.startIndex, offsetBy: 2)], count: 2)
        }
        guard string.count == 6, let uint32 = UInt32(string, radix: 16) else { return nil }
        let r = CGFloat((uint32 & 0x00ff0000) >> 16) / 255
        let g = CGFloat((uint32 & 0x0000ff00) >> 8 ) / 255
        let b = CGFloat((uint32 & 0x000000ff) >> 0 ) / 255
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
