//
//  SafeSelector.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SafeSelector: View {
    var height: CGFloat = 116

    var body: some View {
        HStack(spacing: 0) {
            Image("safe-selector-not-selected-icon")
                .padding()
            Text("No Safe loaded")
                .font(Font.gnoBody.weight(.semibold))
                .foregroundColor(Color.gnoMediumGrey)
            Spacer()
        }
        .frame(height: height, alignment: .bottom)
        .background(
            Rectangle()
                .foregroundColor(Color.gnoSnowwhite)
                .cardShadowTooltip()
        )

    }
}

struct SafeSelector_Previews: PreviewProvider {
    static var previews: some View {
        SafeSelector()
    }
}
