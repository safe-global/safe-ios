//
//  TopTabView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

// The TabView equivalent with the tab bar at the top.
// Currently supports exactly 2 tabs.
struct TopTabView<L0: View, L1: View, C0: View, C1: View>: View {

    typealias Content = TupleView<(TopTabChild<L0, C0>, TopTabChild<L1, C1>)>

    var content: Content

    @State var selection: Int? = 0

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TopTabButton(tag: 0, selection: $selection) {
                    content.value.0.label
                }

                TopTabButton(tag: 1, selection: $selection) {
                    content.value.1.label
                }
            }
            .background(Color.gnoWhite)

            if selection == 0 {
                content.value.0.content.frame(maxHeight: .infinity)
            } else if selection == 1 {
                content.value.1.content.frame(maxHeight: .infinity)
            } else {
                EmptyView()
            }
        }
    }


}


struct BottomBorder: Shape {

    var height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(x: rect.minX, y: rect.maxY - height, width: rect.width, height: height))
        path.closeSubpath()
        return path
    }
}


struct TopTabChild<Label: View, Content: View>: View {

    var label: Label
    var content: Content

    init(@ViewBuilder _ label: () -> Label, @ViewBuilder _ content: () -> Content) {
        self.label = label()
        self.content = content()
    }

    var body: some View {
        content
    }
}

extension View {

    func topTabItem<Label>(@ViewBuilder _ label: () -> Label) -> TopTabChild<Label, Self> where Label: View {
        TopTabChild(label, { self })
    }
}

struct TopTabView_Previews: PreviewProvider {
    static var previews: some View {
        TopTabView {
            Text("Hello")
                .topTabItem {
                    Text("One")
                }

            Text("World")
                .topTabItem {
                    Text("Two")
            }
        }
    }
}
