//
//  Colors.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension Color {

    init(hex: Int) {
        self.init(red: Double((hex >> 16) & 0xFF) / 0xFF,
                  green: Double((hex >> 8) & 0xFF) / 0xFF,
                  blue: Double(hex & 0xFF) / 0xFF)
    }

    enum Gnosis {

        static let hold = Color(hex: 0x008C73)
        static let tomato = Color(hex: 0xF02525)
        static let lightGreen = Color(hex: 0xA1D2CA)

        static let darkBlue = Color(hex: 0x001428)
        static let darkGrey = Color(hex: 0x5D6D74)
        static let mediumGrey = Color(hex: 0xB2B5B2)

        static let lightGrey = Color(hex: 0xD4D5D3)
        static let whitesmoke = Color(hex: 0xE8E7E6)
        static let whitesmokeTwo = Color(hex: 0xF0EFEE)

        static let white = Color(hex: 0xF7F5F5)
        static let systemWhite = Color.white
        static let systemBlack = Color.black

        static let cardShadow = Color(hex: 0xD4D4D3).opacity(0.59)
        static let cardShadowPassword = Color(hex: 0x607E79).opacity(0.36)
        static let cardShadowTooltip = Color(hex: 0x28363D).opacity(0.18)
        static let systemSelection = Color(hex: 0x007AFF).opacity(0.2)

        static let holdTwo = Color(hex: 0x005546)
        static let hold20 = Self.hold.opacity(0.2)
        static let hold50 = Self.hold.opacity(0.5)

        static let black15 = Self.systemBlack.opacity(0.15)
        static let darkBlue50 = Self.darkBlue.opacity(0.5)

    }

}
