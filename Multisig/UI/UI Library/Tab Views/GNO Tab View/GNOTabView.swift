//
//  GNOTabView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 19.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct GNOTabView<SelectionValue: Hashable>: View {
    
    var items: [GNOTabItem<SelectionValue>]

    var selection: Binding<SelectionValue?>

    init(selection: Binding<SelectionValue?>, items: [GNOTabItem<SelectionValue>])  {
        self.selection = selection
        self.items = items
    }

    var body: some View {
        VStack(spacing: 0) {
            if selectedItem != nil {
                selectedItem!.content.frame(maxHeight: .infinity)
            } else {
                EmptyView()
            }

            HStack(spacing: 0) {
                ForEach(items) { item in
                    GNOTabButton(tag: item.id, selection: self.selection) {
                        item.label
                    }
                }
            }
            .frame(height: barHeight, alignment: .top)
            .background(Color.gnoSnowwhite)
        }
        .edgesIgnoringSafeArea(.bottom)
    }

    var selectedItem: GNOTabItem<SelectionValue>? {
        selection.wrappedValue.flatMap { id in items.first { $0.id == id } }
    }

    let bigScreenHeight: CGFloat = 812 // 5.8 inch phones and higher
    let bigScreenBarHeight: CGFloat = 84
    let smallerScreenBarHeight: CGFloat = 64

    var barHeight: CGFloat {
        UIScreen.main.bounds.height >= bigScreenHeight ? bigScreenBarHeight : smallerScreenBarHeight
    }

}

extension GNOTabView {

    // note: custom formatting here to make the declaration easier to read
    // and modify.

    // 1 child view
    init<L, C>(_ selection: Binding<SelectionValue?>, @ViewBuilder _ contentClosure: () ->
        GNOTabChildView<SelectionValue, L, C>
    )
        where
        L: View, C: View
    {
        self.selection = selection
        let content = contentClosure()
        items = [
            GNOTabItem(content)
        ]
    }

    // 2 child views
    init<
        L0, C0,
        L1, C1
        >
    (_ selection: Binding<SelectionValue?>, @ViewBuilder _ contentClosure: () ->
        TupleView<(
        GNOTabChildView<SelectionValue, L0, C0>,
        GNOTabChildView<SelectionValue, L1, C1>
        )>
    )
        where
        L0: View, C0: View,
        L1: View, C1: View
    {
            self.selection = selection
            let content = contentClosure()
            items = [
                GNOTabItem(content.value.0),
                GNOTabItem(content.value.1)
            ]
    }

    // 3 child views
    init<
        L0, C0,
        L1, C1,
        L2, C2
        >
    (_ selection: Binding<SelectionValue?>, @ViewBuilder _ contentClosure: () ->
        TupleView<(
        GNOTabChildView<SelectionValue, L0, C0>,
        GNOTabChildView<SelectionValue, L1, C1>,
        GNOTabChildView<SelectionValue, L2, C2>
        )>
    )
        where
        L0: View, C0: View,
        L1: View, C1: View,
        L2: View, C2: View
    {
            self.selection = selection
            let content = contentClosure()
            items = [
                GNOTabItem(content.value.0),
                GNOTabItem(content.value.1),
                GNOTabItem(content.value.2)
            ]
    }

}


struct GNOTabView_Previews: PreviewProvider {
    static var previews: some View {
        GNOTabView(.constant(0)) {
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
