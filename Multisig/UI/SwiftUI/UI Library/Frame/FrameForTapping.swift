//
//  FrameForTapping.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct FrameForTapping: ViewModifier {

    var alignment: Alignment

    func body(content: Content) -> some View {
        // fixes unbounded growth of this view when inside the bar
        content
            .frame(width: 44, height: 44, alignment: alignment)
    }

}

extension View {

    func frameForTapping(alignment: Alignment = .center) -> some View {
        modifier(FrameForTapping(alignment: alignment))
    }

}
