//
//  AddressText.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 17.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddressText: View {

    private let tailColor = Color.gnoDarkBlue
    private let bodyColor = Color.gnoMediumGrey
    private let prefixCount = 4
    private let suffixCount = 4

    private var text: String

    private var prefix: Substring { text.prefix(prefixCount) }
    private var suffix: Substring { text.suffix(suffixCount) }
    private var middle: Substring { text.dropFirst(prefixCount).dropLast(suffixCount) }

    init(_ text: String) {
        self.text = text
        assert(text.count > prefixCount + suffixCount)
    }

    var body: some View {
        Group {
            Text(prefix).foregroundColor(tailColor) +
            Text(middle).foregroundColor(bodyColor) +
            Text(suffix).foregroundColor(tailColor)
        }
        .font(Font.gnoCallout.weight(.medium))
        .lineLimit(2)
    }

}

struct AddressText_Previews: PreviewProvider {
    static var previews: some View {
        AddressText("hello world, long welcome!")
    }
}
