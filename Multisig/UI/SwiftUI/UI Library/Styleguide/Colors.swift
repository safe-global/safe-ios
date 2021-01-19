//
//  Colors.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension Color {
    static let gnoCardShadowTooltip = Color("cardShadowTooltip")
    static let gnoDarkBlue = Color("darkBlue")
    static let gnoDarkGrey = Color("darkGrey")
    static let gnoHold = Color("hold")
    static let gnoHoldTwo = Color("holdTwo")
    static let gnoLightGrey = Color("lightGrey")
    static let gnoMediumGrey = Color("mediumGrey")
    static let gnoShadow = Color("shadow")
    static let gnoSnowwhite = Color("snowwhite")
    static let gnoTomato = Color("tomato")
    static let gnoPending = Color("pending")
    // This was replaced from Color("white") because
    // table view section header and the TopTabView background
    // colors were different from the UITableView background color.
    // Combined with removing fighting with UITableView.appearance() and
    // SwiftUI that produced different background color stripes.
    static let gnoWhite = Color(UIColor.systemGray6)
    static let gnoWhitesmoke = Color("whitesmoke")
    static let gnoWhitesmokeTwo = Color("whitesmokeTwo")
    static let systemGray6Light = Color("systemGray6Light")
}

extension View {
    func cardShadowTooltip() -> some View {
        shadow(color: .gnoCardShadowTooltip, radius: 10, x: 1, y: 2)
    }

    func gnoShadow() -> some View {
        shadow(color: .gnoShadow, radius: 10, x: 1, y: 2)
    }
}
