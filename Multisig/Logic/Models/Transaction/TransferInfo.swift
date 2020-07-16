//
//  TransferInfo.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransferInfo {
    var from, to: Address
    var amount: UInt256
    var token: Token
}

typealias SafeInfo = SafeStatusRequest.Response

extension Transaction {
    func safeAddress(_ info: SafeInfo) -> Address {
        safe?.address ?? info.address.address
    }
}

extension TransferInfo {

    init(ether tx: Transaction, info: SafeInfo, token: Token) {
        self.init(
            from: tx.safeAddress(info),
            to: tx.to?.address ?? .zero,
            amount: tx.value?.value ?? 0,
            token: token)
    }

    init(ether transfer: TransactionTransfer, tx: Transaction, info: SafeInfo, token: Token) {
        self.init(erc20: transfer, tx: tx, info: info, token: token)
    }

    init(erc20 transfer: TransactionTransfer, tx: Transaction, info: SafeInfo, token: Token) {
        self.init(
            from: transfer.from.address,
            to: transfer.to.address,
            amount: transfer.value?.value ?? 0,
            token: token)
    }

    init(erc20 method: TransferMethod,  tx: Transaction, info: SafeInfo, token: Token) {
        self.init(
            from: method.from ?? tx.safeAddress(info),
            to: method.to,
            amount: method.amount,
            token: token)
    }

    init(erc721 transfer: TransactionTransfer, tx: Transaction, info: SafeInfo, token: Token) {
        self.init(
            from: transfer.from.address,
            to: transfer.to.address,
            amount: 1,
            token: token)
    }

    init(erc721 method: TransferMethod,  tx: Transaction, info: SafeInfo, token: Token) {
        self.init(
        from: method.from ?? tx.safeAddress(info),
        to: method.to,
        amount: 1,
        token: token)
    }
}

extension Token {

    init(erc721 tokenAddress: Address) {
        self.init(
            type: .erc721,
            address: tokenAddress,
            logo: nil,
            name: "ERC721",
            symbol: "NFT",
            decimals: 0)
    }

    init(erc20 tokenAddress: Address) {
        self.init(
            type: .erc20,
            address: tokenAddress,
            logo: nil,
            name: "ERC20",
            symbol: "ERC20",
            decimals: 0)
    }

}
