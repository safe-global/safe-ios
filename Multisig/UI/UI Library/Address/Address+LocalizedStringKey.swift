//
//  Address+LocalizedStringKey.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 17.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension LocalizedStringKey.StringInterpolation {
    mutating func appendInterpolation(_ value: Address) {
        appendLiteral(value.description)
    }
}
