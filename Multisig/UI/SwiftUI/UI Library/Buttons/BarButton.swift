//
//  BarButton.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BarButtonModifier: ViewModifier {

    var disabled: Bool

    func body(content: Content) -> some View {
        content
            .font(Font.body.bold())
            .disabled(disabled)
            .accentColor(disabled ? .backgroundSecondary :  .primary)
    }

}

extension View {

    func barButton(disabled: Bool = false) -> some View {
        modifier(BarButtonModifier(disabled: disabled))
    }

}

struct BarButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Button("Hello") {}.barButton(disabled: true)//.disabled(true)
        }
    }
}
