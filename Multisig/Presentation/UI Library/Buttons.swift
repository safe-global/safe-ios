//
//  Buttons.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct GNOFilledButtonStyle: ButtonStyle {
    var width: CGFloat? = 270

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .font(Font.gnoBody.bold())
            .frame(width: width)
            .background(configuration.isPressed ? Color.gnoHoldTwo : .gnoHold)
            .foregroundColor(.gnoSnowwhite)
            .cornerRadius(10)
            .cardShadowTooltip()
    }
}

struct GNOBorderedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .font(Font.gnoBody.bold())
            .foregroundColor(color(configuration))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                .stroke(color(configuration), lineWidth: 2)
            )
    }

    func color(_ configuration: Configuration) -> Color {
        configuration.isPressed ?
            Color.gnoDarkBlue.opacity(0.7) : .gnoDarkBlue
    }
}

struct GNOPlainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .font(Font.gnoBody.bold())
            .foregroundColor(
                configuration.isPressed ? Color.gnoHoldTwo : .gnoHold)
    }
}

struct Buttons_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            Button("Hello, World!", action: {}).buttonStyle(GNOFilledButtonStyle(width: 150))
            Button("Hello, World!", action: {}).buttonStyle(GNOBorderedButtonStyle())
            Button("Hello, World!", action: {}).buttonStyle(GNOPlainButtonStyle())
        }
    }
}
