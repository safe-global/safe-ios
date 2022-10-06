//
//  Colors.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension Color {
    static let primary = Color("primary")
    static let splashBackgroundPrimary = Color("splashBackgroundPrimary")
    static let primaryPressed = Color("primaryPressed")
    static let primaryDisabled = Color("primaryDisabled")
    static let error = Color("error")
    static let errorPressed = Color("errorPressed")
    static let icon = Color("icon")
    static let separator = Color("separator")
    static let border = Color("border")
    static let shadow = Color("shadow")
    static let backgroundPrimary = Color("backgroundPrimary")
    static let backgroundSecondary = Color("backgroundSecondary")
    static let labelPrimary = Color("labelPrimary")
    static let labelSecondary = Color("labelSecondary")
    static let labelTetriary = Color("labelTetriary")
    static let splashBackground = Color("splashBackground")
}

extension View {
    func gnoShadow() -> some View {
        shadow(color: .shadow, radius: 10, x: 1, y: 2)
    }
}
