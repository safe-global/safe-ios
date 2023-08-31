//
//  UIColor+Styles.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 29.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UIColor {
    // Foundation
    static let primary = UIColor(named: "primary")!
    static let primaryPressed = UIColor(named: "primaryPressed")!
    static let primaryDisabled = UIColor(named: "primaryDisabled")!
    // Background
    static let backgroundPrimary = UIColor(named: "backgroundPrimary")!
    static let backgroundSecondary = UIColor(named: "backgroundSecondary")!
    static let backgroundLightGreen = UIColor(named: "backgroundLightGreen")!
    static let backgroundGreen = UIColor(named: "backgroundGreen")!
    static let backgroundTweet = UIColor(named: "backgroundTweet")!
    static let splashBackground = UIColor(named:"splashBackground")!
    static let backgroundTertiary = UIColor(named:"backgroundTertiary")!

    // Components
    static let icon = UIColor(named: "icon")!
    static let separator = UIColor(named: "separator")!
    static let border = UIColor(named: "border")!
    static let borderSelected = UIColor(named: "borderSelected")!
    static let borderDisabled = UIColor(named: "borderDisabled")
    // Label
    static let labelPrimary = UIColor(named: "labelPrimary")!
    static let labelSecondary = UIColor(named: "labelSecondary")!
    static let labelTertiary = UIColor(named: "labelTetriary")!
    static let labelDisabled = UIColor(named: "labelDisabled")
    static let primaryInverted = UIColor(named: "primaryInverted")
    // Error
    static let error = UIColor(named: "error")!
    static let errorPressed = UIColor(named: "errorPressed")!
    static let errorBackground = UIColor(named: "errorBackground")!
    // Warning
    static let warning = UIColor(named: "warning")!
    static let warningPressed = UIColor(named: "warningPressed")
    static let warningBackground = UIColor(named: "warningBackground")!

    // Info
    static let info = UIColor(named: "info")!
    static let infoPressed = UIColor(named: "infoPressed")!
    static let infoBackground = UIColor(named: "infoBackground")!
    static let success = UIColor(named: "success")!
    static let baseSuccess = UIColor(named: "baseSuccess")!
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
