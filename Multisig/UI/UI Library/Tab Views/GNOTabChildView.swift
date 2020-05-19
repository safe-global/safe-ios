//
//  TopTabChildView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

// Wraps together label and content view to be used in the TopTabView
struct GNOTabChildView<SelectionValue: Hashable, Label: View, Content: View>: View {

    var id: SelectionValue
    var label: Label
    var content: Content

    var body: some View {
        content
    }
}

extension View {
    func gnoTabItem<SelectionValue, Label>(id: SelectionValue, @ViewBuilder _ label: () -> Label)
        -> GNOTabChildView<SelectionValue, Label, Self> where Label: View, SelectionValue: Hashable {
            GNOTabChildView(id: id, label: label(), content: self)
    }
}

extension GNOTabItem {

    init<L, C>(_ view: GNOTabChildView<SelectionValue, L, C>) where L: View, C: View {
        self.init(id: view.id, label: AnyView(view.label), content: AnyView(view.content))
    }
}
