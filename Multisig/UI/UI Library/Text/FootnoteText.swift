//
//  FootnoteText.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 19.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct FootnoteText: View {
    var label: String

    var foregroundColor: Color
    init(_ value: String, color: Color = .gnoDarkGrey) {
        label = value
        foregroundColor = color
    }

    var body: some View {
        Text(label).font(Font.gnoFootnote.weight(.medium)).foregroundColor(foregroundColor)
    }
}

struct FootnoteText_Previews: PreviewProvider {
    static var previews: some View {
        FootnoteText("Hello")
    }
}
