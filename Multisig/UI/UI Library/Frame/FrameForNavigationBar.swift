//
//  FrameForNavigationBar.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct FrameForNavigationBar: ViewModifier {

    func body(content: Content) -> some View {
        // fixes unbounded growth of this view when inside the bar
        content
            .frame(width: 250, height: 44, alignment: .leading)
    }

}

extension View {

    func frameForNavigationBar() -> some View {
        modifier(FrameForNavigationBar())
    }

}
