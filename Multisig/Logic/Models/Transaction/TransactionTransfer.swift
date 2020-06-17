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
    let address: AddressString
    let decimals: UInt256String?
    let symbol: String?
    let name: String?
    let logoUri: String?
    let tokenType: TokenType?
}

enum TokenType: String, Decodable {
    case erc20 = "ERC20"
    case erc721 = "ERC721"
}
