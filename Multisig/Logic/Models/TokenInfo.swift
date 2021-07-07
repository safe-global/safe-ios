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
    // *nativeCoin*
    case ether = "ETHER"
}

extension Token {

    init(_ token: TokenInfo) {
        type = token.type
        address = token.address.address
        logo = token.logoUri.flatMap { URL(string: $0) }
        name = token.name ?? (token.type == .erc20 ? "ERC20" : "ERC721")
        symbol = token.symbol ?? (token.type == .erc20 ? "ERC20" : "NFT")
        decimals = token.decimals?.value ?? 0

        // *nativeCoin*
        if type == .ether {
            address = .ether
            logo = nil
            name = "Ether"
            symbol = "ETH"
            decimals = 18
        }
    }

}
