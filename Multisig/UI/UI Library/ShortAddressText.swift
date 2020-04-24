//
//  ShortAddressText.swift
//  Multisig
//
//  Created by Moaaz on 4/23/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ShortAddressText: View {
    private let bodyColor = Color.gnoMediumGrey
    private var prefixCount = 4
    private var suffixCount = 4

    private var text: String

    private var prefix: Substring { text.prefix(prefixCount) }
    private var suffix: Substring { text.suffix(suffixCount) }

    init(_ text: String) {
        self.text = text
        assert(text.count > prefixCount + suffixCount)
    }
    
    init(_ text: String, prefixCount: Int, suffixCount: Int) {
        self.prefixCount = prefixCount
        self.suffixCount = suffixCount
        self.text = text
        assert(text.count > prefixCount + suffixCount)
    }

    var body: some View {
        Group {
            Text(prefix).foregroundColor(bodyColor) +
            Text("...").foregroundColor(bodyColor) +
            Text(suffix).foregroundColor(bodyColor)
        }
        .font(Font.gnoCallout.weight(.medium))
        .lineLimit(2)
    }

}

struct ShortAddressText_Previews: PreviewProvider {
    static var previews: some View {
        ShortAddressText("hello world, long welcome!")
    }
}
