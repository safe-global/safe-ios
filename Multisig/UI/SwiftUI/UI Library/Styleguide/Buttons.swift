//
//  Buttons.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct GNOFilledButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .font(.gnoHeadline2)
            .background(configuration.isPressed ? Color.buttonPressed : .button)
            .foregroundColor(.primaryBackground)
            .cornerRadius(10)
            .cardShadowTooltip()
    }
}

struct GNOBorderedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .font(.gnoHeadline2)
            .foregroundColor(color(configuration))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                .stroke(color(configuration), lineWidth: 2)
            )
    }

    func color(_ configuration: Configuration) -> Color {
        configuration.isPressed ? Color.labelPrimary.opacity(0.7) : .labelPrimary
    }
}

struct GNOPlainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .font(.gnoBody)
            .foregroundColor(
                configuration.isPressed ? Color.buttonPressed : .button)
    }
}


struct GNOCustomButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        CustomButton(normalColor: color,
                     disabledColor: .buttonDisabled,
                     configuration: configuration)
    }

    struct CustomButton: View {
        var normalColor: Color
        var disabledColor: Color
        var configuration: GNOCustomButtonStyle.Configuration
        @Environment(\.isEnabled) var isEnabled: Bool

        var body: some View {
            configuration.label
                .padding()
                .font(.gnoBody)
                .foregroundColor(isEnabled ? normalColor : disabledColor)
                .opacity(configuration.isPressed ? 0.5 : 1)
        }
    }

}

struct Buttons_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            Button("Hello, World!", action: {}).buttonStyle(GNOFilledButtonStyle())
            Button("Hello, World!", action: {}).buttonStyle(GNOBorderedButtonStyle())
            Button("Hello, World!", action: {}).buttonStyle(GNOPlainButtonStyle())
        }
    }
}
