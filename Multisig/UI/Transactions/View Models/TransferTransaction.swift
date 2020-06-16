//
//  TransferTransaction.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftCryptoTokenFormatter

class TransferTransaction: BaseTransactionViewModel {

    var address: String
    var isOutgoing: Bool
    var amount: String
    var tokenSymbol: String

    override init() {
        address = ""
        isOutgoing = true
        amount = ""
        tokenSymbol = ""
        super.init()
    }


    convenience init(transfer: TransactionTransfer, tx: Transaction, safe: SafeStatusRequest.Response) {
        self.init(
            from: transfer.from.address,
            to: transfer.to.address,
            safe: tx.safe?.address ?? safe.address.address,
            erc721: transfer.type == .erc721,
            value: transfer.value?.value,
            tokenAddress: transfer.tokenAddress?.address,
            date: transfer.executionDate,
            status: .success,
            tx: tx,
            safeInfo: safe)
    }

    init(from: Address,
         to: Address,
         safe: Address,
         erc721: Bool,
         value: UInt256?,
         tokenAddress: Address?,
         date: Date?,
         status: TransactionStatus?,
         tx: Transaction,
         safeInfo: SafeStatusRequest.Response) {

        isOutgoing = from == safe
        let correspondent = (isOutgoing ? to : from)
        address = correspondent.checksummed
        // setting the amount and token
        do {
            let formatter = TokenFormatter()
            let amountInt: Int256
            if erc721 {
                amountInt = 1
            } else {
                amountInt = value.map { Int256($0) } ?? 0
            }

            let addr = tokenAddress ?? AddressRegistry.ether
            let token = App.shared.tokenRegistry[addr]

            let sign: Int256 = isOutgoing ? -1 : +1
            let precision = token?.decimals.value ?? 0
            let amountDecimal = BigDecimal(sign * amountInt,
                                           Int(clamping: precision))

            amount = formatter.string(
                from: amountDecimal,
                decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
                thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
                forcePlusSign: true)
            tokenSymbol = token?.symbol ?? ""
        }

        super.init(tx, safeInfo)

        if let date = date {
            self.date = date
            formattedDate = Self.dateFormatter.string(from: date)
        }
        if let status = status {
            self.status = status
        }
    }


    // typealiases for shorter source code line length
    fileprivate typealias Erc20Transfer = MethodRegistry.ERC20.Transfer
    fileprivate typealias Erc20TransferFrom = MethodRegistry.ERC20.TransferFrom
    fileprivate typealias Erc721SafeTransferFrom = MethodRegistry.ERC721.SafeTransferFrom

    override convenience init(_ tx: Transaction, _ safe: SafeStatusRequest.Response) {
        let safeAddress = tx.safe?.address ?? safe.address.address

        // Decoding the transfer parameters
        let from: Address, to: Address, amount: UInt256
        var isERC721 = false
        var tokenAddress = tx.to?.address ?? AddressRegistry.ether

        // ERC20
        if let data = tx.dataDecoded, let call = Erc20Transfer(data: data) {
            (from, to, amount) = (safeAddress, call.to, call.amount)

        } else if let data = tx.dataDecoded, let call = Erc20TransferFrom(data: data) {
            (from, to, amount) = (call.from, call.to, call.amount)

        // ERC721
        } else if let data = tx.dataDecoded, let call = Erc721SafeTransferFrom(data: data) {
            (from, to, amount) = (call.from, call.to, 1)
            isERC721 = true

        // Ether
        } else {
            from = safeAddress
            to = tx.to?.address ?? .zero
            amount = tx.value?.value ?? 0
            tokenAddress = AddressRegistry.ether
        }

        self.init(
            from: from,
            to: to,
            safe: safeAddress,
            erc721: isERC721,
            value: amount,
            tokenAddress: tokenAddress,
            date: nil,
            status: nil,
            tx: tx,
            safeInfo: safe)
    }
}
