//
//  TransactionTransfer.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TokenInfo: Decodable, Hashable {
    let type: TokenType
    let address: AddressString
    let name: String?
    let symbol: String?
    let decimals: UInt256String?
    let logoUri: String?
}

enum TokenType: String, Decodable {
    case erc20 = "ERC20"
    case erc721 = "ERC721"
    case ether = "ETHER"
}
