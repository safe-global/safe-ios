//
//  AddressText.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 17.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddressText: View {

    enum Style {
        case short, long
    }

    private let tailColor = Color.gnoDarkBlue
    private let bodyColor = Color.gnoMediumGrey

    private var text: String
    private var prefixCount: Int
    private var suffixCount: Int
    private var style: Style

    private var prefix: String { String(text.prefix(prefixCount)) }
    private var suffix: String { String(text.dropFirst(prefixCount).suffix(suffixCount)) }
    private var middle: String { String(text.dropFirst(prefixCount).dropLast(suffixCount)) }

    init(_ text: String, style: Style = .long, prefixCount: Int = 4, suffixCount: Int = 4) {
        self.text = text
        self.style = style
        self.prefixCount = prefixCount
        self.suffixCount = suffixCount
    }

    var body: Text {
        (style == .long ? longText : shortText).tracking(-0.41)
    }

    var longText: Text {
        Text(prefix).foregroundColor(tailColor) +
        Text(middle).foregroundColor(bodyColor) +
        Text(suffix).foregroundColor(tailColor)
    }

    var shortText: Text {
        Text("\(prefix)…\(suffix)").foregroundColor(bodyColor)
    }

}

struct AddressText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AddressText("Some text long", style: .short)
            AddressText("hello world, long welcome!")
            AddressText("")
            AddressText("hey")
        }
    }
}
