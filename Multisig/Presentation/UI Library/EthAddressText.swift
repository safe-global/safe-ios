//
//  EthAddressText.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct EthAddressText: View {
    var address: EthAddress

    var prefixLength: Int = 4
    var suffixLength: Int = 4

    var accentColor: Color = .gnoDarkBlue
    var baseColor: Color = .gnoMediumGrey

    var body: some View {
        let value = address.checksummed
        let prefix = value.prefix(prefixLength)
        let base = value.dropFirst(prefixLength).dropLast(suffixLength)
        let suffix = value.suffix(suffixLength)
        let text = Text(prefix).foregroundColor(accentColor) +
                Text(base).foregroundColor(baseColor) +
                Text(suffix).foregroundColor(accentColor)
        return text.font(Font.gnoCallout.weight(.medium))
    }
}

struct EthAddressText_Previews: PreviewProvider {
    static var previews: some View {
        EthAddressText(address: "0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826")
            .frame(width: 220)
    }
}
