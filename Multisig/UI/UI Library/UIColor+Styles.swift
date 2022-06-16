//
//  UIColor+Styles.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 29.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UIColor {
    static let primary = UIColor(named: "primary")!
    static let primaryPressed = UIColor(named: "primaryPressed")!
    static let primaryDisabled = UIColor(named: "primaryDisabled")!
    static let cardShadowTooltip = UIColor(named: "cardShadowTooltip")!
    static let error = UIColor(named: "error")!
    static let errorPressed = UIColor(named: "errorPressed")!
    static let rejection = UIColor(named: "errorDisabled")!
    static let icon = UIColor(named: "icon")!
    static let pending = UIColor(named: "warning")!
    static let separator = UIColor(named: "separator")!
    static let backgroundPrimary = UIColor(named: "backgroundPrimary")!
    static let backgroundSecondary = UIColor(named: "backgroundSecondary")!
    static let backgroundTertiary = UIColor(named: "backgroundTetriary")!
    static let backgroundQuaternary = UIColor(named: "backgroundQuaternary")!
    static let backgroundPositive = UIColor(named: "backgroundPositive")!
    static let backgroundWarning = UIColor(named: "backgroundWarning")!
    static let backgroundError = UIColor(named: "backgroundError")!
    static let whiteOrBlack = UIColor(named: "backgroundWhiteOrBlack")!
    static let labelPrimary = UIColor(named: "labelPrimary")!
    static let labelSecondary = UIColor(named: "labelSecondary")!
    static let labelTertiary = UIColor(named: "labelTetriary")!
    static let border = UIColor(named: "border")!
    static let splashBackground = UIColor(named:"splashBackground")!
}

extension UIColor {
    convenience init?(hex: String) {
        guard hex.hasPrefix("#") else { return nil }
        var string = hex
        string.removeFirst()
        guard string.count == 6, let uint32 = UInt32(string, radix: 16) else { return nil }
        let r = CGFloat((uint32 & 0x00ff0000) >> 16) / 255
        let g = CGFloat((uint32 & 0x0000ff00) >> 8 ) / 255
        let b = CGFloat((uint32 & 0x000000ff) >> 0 ) / 255
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
