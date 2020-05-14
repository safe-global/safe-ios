//
//  BottomBorder.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

// Draws a configurable-height bottom border
struct BottomBorder: Shape {

    var height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(x: rect.minX,
                            y: rect.maxY - height,
                            width: rect.width,
                            height: height))
        path.closeSubpath()
        return path
    }
}
