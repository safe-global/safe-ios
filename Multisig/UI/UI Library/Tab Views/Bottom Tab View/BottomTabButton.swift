//
//  GNOTabButton.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 19.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BottomTabButton<SelectionValue: Hashable, Content: View>: View {
    
    var tag: SelectionValue
    var selection: Binding<SelectionValue?>
    var content: Content

    init(tag: SelectionValue, selection: Binding<SelectionValue?>, @ViewBuilder _ content: () -> Content) {
        self.tag = tag
        self.selection = selection
        self.content = content()
    }

    var body: some View {
        Button(action: select) {
            if isSelected {
                label.accentColor(Color.gnoHold)
            } else {
                label.accentColor(Color.gnoDarkGrey)
            }
        }
        .font(Font.gnoCaption2.weight(.medium))
    }

    var isSelected: Bool {
        selection.wrappedValue == tag
    }

    func select() {
        selection.wrappedValue = tag
    }

    var label: some View {
        content
            .padding(5)
            .frame(maxWidth: .infinity)
    }
    
}

struct BottomTabButton_Previews: PreviewProvider {
    static var previews: some View {
        BottomTabButton(tag: 0, selection: .constant(0)) {
            VStack {
                Image(systemName: "star.filled")
                Text("Button")
            }
        }
    }
}
