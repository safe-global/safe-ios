//
//  TopTabChildView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TopTabChildView<Label: View, Content: View>: View {

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

    func topTabItem<Label>(@ViewBuilder _ label: () -> Label) -> TopTabChildView<Label, Self> where Label: View {
        TopTabChildView(label, { self })
    }
}
