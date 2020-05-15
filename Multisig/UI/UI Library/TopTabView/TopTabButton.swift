//
//  TopTabButton.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

// TopTabView's tab bar button that spans the full available width.
// Changes appearance dependinig on the selection.
struct TopTabButton<Content: View>: View {

    var tag: Int
    var selection: Binding<Int?>
    var content: Content

    init(tag: Int, selection: Binding<Int?>, @ViewBuilder _ content: () -> Content) {
        self.tag = tag
        self.selection = selection
        self.content = content()
    }

    var body: some View {
        Button(action: select) {
            if isSelected {
                label.background(BottomBorder(width: 2))
            } else {
                label.accentColor(Color.gnoMediumGrey)
            }
        }
    }

    var isSelected: Bool {
        selection.wrappedValue == tag
    }

    func select() {
        selection.wrappedValue = tag
    }

    var label: some View {
        content
            .padding()
            .frame(height: 56)
            .frame(maxWidth: .infinity)
    }

}

struct TopTabButton_Previews: PreviewProvider {
    static var previews: some View {
        TopTabButton(tag: 0, selection: .constant(0)) {
            Text("Button")
        }
    }
}
