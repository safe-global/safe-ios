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
            .font(.button)
            .background(configuration.isPressed ? Color.primaryPressed : .primary)
            .foregroundColor(.backgroundPrimary)
            .cornerRadius(6)
    }
}

struct GNOFilledGreenButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .font(.button)
            .background(Color.primary)
            .foregroundColor(Color.backgroundPrimary)
            .cornerRadius(6)
    }
}

struct GNOBorderedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .font(.button)
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
            .padding(4)
            .font(.button)
            .foregroundColor(
                configuration.isPressed ? Color.primaryPressed : .primary)
    }
}


struct GNOCustomButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        CustomButton(normalColor: color,
                     disabledColor: .primaryDisabled,
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
                .font(.button)
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
