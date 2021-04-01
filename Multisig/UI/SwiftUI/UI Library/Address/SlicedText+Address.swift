//
//  SlicedText+Address.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension SlicedText.Style {
    static let addressShortLight = Self.init(color: .tertiaryLabel, truncate: .middle)
    static let addressShortDark = Self.init(color: .primaryLabel, truncate: .middle)
    static let addressLong = Self.init(middleColor: .tertiaryLabel, sideColor: .primaryLabel, truncate: .none)
}

extension SlicedText {
    init(_ address: Address) {
        self.init(string: SlicedString(text: address.checksummed, prefix: 6, suffix: 4),
                  style: .addressLong)
    }
}

