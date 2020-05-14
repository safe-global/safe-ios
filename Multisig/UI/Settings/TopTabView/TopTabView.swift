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

    // Swift generics + type inference will make sure that this class
    // will compile only when the content has 2 child views.
    typealias Content = TupleView<(TopTabChildView<L0, C0>, TopTabChildView<L1, C1>)>

    var items: [Item]

    @State var selection: Int? = 0

    init(@ViewBuilder _ contentClosure: () -> Content) {
        let content = contentClosure()
        items = [
            Item(id: 0, label: AnyView(content.value.0.label), content: AnyView(content.value.0.content)),
            Item(id: 1, label: AnyView(content.value.1.label), content: AnyView(content.value.1.content)),
        ]
    }

    init(items: [Item]) {
        self.items = items
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(items) { item in
                    TopTabButton(tag: item.id, selection: self.$selection) {
                        item.label
                    }
                }
            }
            .background(Color.gnoWhite)

            if selection != nil {
                items[selection!].content.frame(maxHeight: .infinity)
            } else {
                EmptyView()
            }
        }
    }

    struct Item: Identifiable {
        var id: Int
        var label: AnyView
        var content: AnyView
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
