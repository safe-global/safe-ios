//
//  TopTabChildView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

// Wraps together label and content view to be used in the TopTabView
struct TopTabChildView<Label: View, Content: View>: View {

    var label: Label
    var content: Content

    var body: some View {
        content
    }
}

extension View {
    func topTabItem<Label>(@ViewBuilder _ label: () -> Label)
        -> TopTabChildView<Label, Self> where Label: View {
            TopTabChildView(label: label(), content: self)
    }
}
