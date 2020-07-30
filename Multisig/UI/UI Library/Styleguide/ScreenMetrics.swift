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

    static var isBigScreen: Bool {
        UIScreen.main.bounds.height >= _5_8_inchScreenHeight
    }

    static var bottomTabHeight: CGFloat {
        isBigScreen ? 84 : 64
    }

    static var aboveTabBar: CGFloat {
        Spacing.extraSmall + (isBigScreen ? 52 : 64)
    }

    static func aboveKeyboard(_ frame: CGRect) -> CGFloat {
        frame.height + (isBigScreen ? -Spacing.medium : Spacing.medium)
    }

    static var aboveBottomEdge: CGFloat {
        isBigScreen ? 0 : Spacing.medium
    }

    static var safeHeaderHeight: CGFloat {
        isBigScreen ? 116 : 96
    }
}
