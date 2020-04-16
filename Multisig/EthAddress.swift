//
//  EthAddress.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct EthAddress: ExpressibleByStringLiteral {

    var _value: String

    init(stringLiteral value: StringLiteralType) {
        // save value
        _value = value
    }

    var checksummed: String {
        _value
    }
}
