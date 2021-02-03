//
//  Colors.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension Color {
    static let button = Color("button")
    static let buttonPressed = Color("buttonPressed")
    static let cardShadowTooltip = Color("cardShadowTooltip")
    static let error = Color("error")
    static let errorPressed = Color("errorPressed")
    static let gray2 = Color("gray2")
    static let gray4 = Color("gray4")
    static let gray5 = Color("gray5")
    static let pending = Color("pending")
    static let primaryBackground = Color("primaryBackground")
    static let primaryLabel = Color("primaryLabel")
    static let secondaryBackground = Color("secondaryBackground")
    static let secondaryLabel = Color("secondaryLabel")
    static let separator = Color("separator")
    static let shadow = Color("shadow")
    static let tertiaryBackground = Color("tertiaryBackground")
    static let tertiaryLabel = Color("tertiaryLabel")
}

extension View {
    func cardShadowTooltip() -> some View {
        shadow(color: .cardShadowTooltip, radius: 10, x: 1, y: 2)
    }

    func gnoShadow() -> some View {
        shadow(color: .shadow, radius: 10, x: 1, y: 2)
    }
}
