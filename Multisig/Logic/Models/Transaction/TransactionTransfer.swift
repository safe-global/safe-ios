//
//  TransactionTransfer.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionTransfer: Decodable, Hashable {
    let type: TransactionTransferType
    let executionDate: Date
    let blockNumber: UInt256String
    let transactionHash: DataString
    let to: AddressString
    let value: UInt256String?
    let tokenId: UInt256String?
    let tokenAddress: AddressString? // should be removed when tokenInfo implemented https://github.com/gnosis/safe-transaction-service/issues/96
    let tokenInfo: TokenInfo?
    let from: AddressString
}

enum TransactionTransferType: String, Decodable {
    case ether = "ETHER_TRANSFER"
    case erc20 = "ERC20_TRANSFER"
    case erc721 = "ERC721_TRANSFER"
    case unknown = "UNKNOWN"
}

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
}

func == (lhs: TransactionTransferType, rhs: TokenType) -> Bool {
    lhs == TransactionTransferType.erc20 && rhs == TokenType.erc20 ||
        lhs == TransactionTransferType.erc721 && rhs == TokenType.erc721
}

func != (lhs: TransactionTransferType, rhs: TokenType) -> Bool {
    !(lhs == rhs)
}

extension Token {

    init(_ token: TokenInfo) {
        type = token.type
        address = token.address.address
        logo = token.logoUri.flatMap { URL(string: $0) }
        name = token.name ?? (token.type == .erc20 ? "ERC20" : "ERC721")
        symbol = token.symbol ?? (token.type == .erc20 ? "ERC20" : "NFT")
        decimals = token.decimals?.value ?? 0
    }

}
