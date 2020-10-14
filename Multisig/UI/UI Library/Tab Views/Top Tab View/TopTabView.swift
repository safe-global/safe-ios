//
//  TopTabView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

// The TabView equivalent with the tab bar at the top.
// Currently supports 1 or 2 tabs.
struct TopTabView<SelectionValue: Hashable>: View {

    var items: [TabViewItem<SelectionValue>]

    var selection: Binding<SelectionValue?>

    init(_ selection: Binding<SelectionValue?>, items: [TabViewItem<SelectionValue>]) {
        self.selection = selection
        self.items = items
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                ForEach(items) { item in
                    TopTabButton(tag: item.id, selection: self.selection) {
                        item.label
                    }
                }
            }
            .frame(height: ScreenMetrics.topTabHeight)
            .background(Color.gnoWhite)
            Divider()

            if selectedItem != nil {
                selectedItem!.content.frame(maxHeight: .infinity)
            } else {
                EmptyView()
            }
        }
    }

    var selectedItem: TabViewItem<SelectionValue>? {
        selection.wrappedValue.flatMap { id in items.first { $0.id == id } }
    }

}

extension TopTabView {

    // 1 child view
    init<L, C>(_ selection: Binding<SelectionValue?>, @ViewBuilder _ contentClosure: () ->
        TabChildView<SelectionValue, L, C>
    )
        where
        L: View, C: View
    {
        self.selection = selection
        let content = contentClosure()
        items = [
            TabViewItem(content)
        ]
    }

    // 2 child views
    // note: custom formatting here to make the declaration easier to read
    // and modify.
    init<
        L0, C0,
        L1, C1
        >
    (_ selection: Binding<SelectionValue?>, @ViewBuilder _ contentClosure: () ->
        TupleView<(
        TabChildView<SelectionValue, L0, C0>,
        TabChildView<SelectionValue, L1, C1>
        )>
    )
        where
        L0: View, C0: View,
        L1: View, C1: View
    {
            self.selection = selection
            let content = contentClosure()
            items = [
                TabViewItem(content.value.0),
                TabViewItem(content.value.1)
            ]
    }

}

struct TopTabView_Previews: PreviewProvider {
    static var previews: some View {
        TopTabView(.constant(0)) {
            Text("Hello")
                .gnoTabItem(id: 0) {
                    Text("One")
                }

            Text("World")
                .gnoTabItem(id: 1) {
                    Text("Two")
            }
        }
    }
}
