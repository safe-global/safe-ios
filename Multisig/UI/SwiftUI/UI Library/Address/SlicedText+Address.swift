//
//  SlicedText+Address.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension SlicedText.Style {
    static let addressShortLight = Self.init(color: .labelTertiary, truncate: .middle)
    static let addressShortDark = Self.init(color: .labelPrimary, truncate: .middle)
    static let addressLong = Self.init(middleColor: .labelTertiary, sideColor: .labelPrimary, truncate: .none)
}

extension SlicedText {
    init(_ address: Address) {
        self.init(string: SlicedString(text: address.checksummed, prefix: 6, suffix: 4),
                  style: .addressLong)
    }
}

