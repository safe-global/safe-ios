//
//  ScreenMetrics.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 30.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

enum ScreenMetrics {
    private static let _5_8_inchScreenHeight: CGFloat = 812

    static let topTabHeight: CGFloat = 56

    static let offscreen: CGFloat = -200

    static var isBigScreen: Bool {
        UIScreen.main.bounds.height >= _5_8_inchScreenHeight
    }

    static var bottomTabHeight: CGFloat {
        isBigScreen ? 84 : 64
    }

    static var aboveTabBar: CGFloat {
        return Spacing.extraSmall + 64
    }

    static func aboveKeyboard(_ frame: CGRect) -> CGFloat {
        frame.height + Spacing.medium
    }

    static var aboveBottomEdge: CGFloat {
        isBigScreen ? Spacing.extraSmall : Spacing.medium
    }

    static var safeHeaderHeight: CGFloat {
        isBigScreen ? 116 : 96
    }
}
