//
//  Token.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct Token: Hashable {
    var type: TokenType
    var address: Address
    var logo: URL?
    var name: String
    var symbol: String
    var decimals: UInt256
}
