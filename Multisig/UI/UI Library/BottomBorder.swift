//
//  Underline.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

// Draws a horizontal underline at the bottom of the frame rectangle.
struct BottomBorder: Shape {

    var width: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(x: rect.minX,
                            y: rect.maxY - width,
                            width: rect.width,
                            height: width))
        path.closeSubpath()
        return path
    }
}
