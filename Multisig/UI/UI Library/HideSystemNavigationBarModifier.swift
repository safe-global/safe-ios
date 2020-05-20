//
//  ShowSystemNavigationBarModifier.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 19.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct HideSystemNavigationBarModifier: ViewModifier {

    var value: Bool = false

    func body(content: Content) -> some View {
        content
        .onAppear {
            withAnimation {
                App.shared.viewState.hidesNavbar = self.value
            }
        }
        .onDisappear {
            withAnimation {
                App.shared.viewState.hidesNavbar = !self.value
            }
        }
    }

}

extension View {
    func hidesSystemNavigationBar(_ value: Bool) -> some View {
        modifier(HideSystemNavigationBarModifier(value: value))
    }
}
