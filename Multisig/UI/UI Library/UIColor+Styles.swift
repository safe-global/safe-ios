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
    static let icon = UIColor(named: "icon")!
    // EFEEED
    static let gray5 = UIColor(named: "gray5")!
    static let whiteOrBlack = UIColor(named: "whiteOrBlackBackground")!
    static let pending = UIColor(named: "pending")!
    static let backgroundPrimary = UIColor(named: "backgroundPrimary")!
    static let labelPrimary = UIColor(named: "labelPrimary")!
    static let backgroundSecondary = UIColor(named: "backgroundSecondary")!
    static let labelSecondary = UIColor(named: "labelSecondary")!
    static let separator = UIColor(named: "separator")!
    static let backgroundTetriary = UIColor(named: "backgroundTetriary")!
    static let labelTertiary = UIColor(named: "labelTertiary")!
    static let quaternaryBackground = UIColor(named: "quaternaryBackground")!
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
