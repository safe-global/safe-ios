//
//  TransferTransaction.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftCryptoTokenFormatter

class TransferTransactionViewModel: TransactionViewModel {

    var address: String
    var isOutgoing: Bool
    var amount: String
    var tokenSymbol: String
    var tokenLogoURL: String

    override init() {
        address = ""
        isOutgoing = true
        amount = ""
        tokenSymbol = ""
        tokenLogoURL = ""
        super.init()
    }

    convenience init(transfer: TransactionTransfer, tx: Transaction, safe: SafeStatusRequest.Response) {
        self.init(
            from: transfer.from.address,
            to: transfer.to.address,
            safe: tx.safe?.address ?? safe.address.address,
            erc721: transfer.type == .erc721,
            value: transfer.value?.value,
            tokenAddress: transfer.tokenAddress?.address ?? AddressRegistry.ether,
            date: transfer.executionDate,
            status: .success,
            hash: transfer.transactionHash,
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
         hash: DataString? = nil,
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
            let precision = token?.decimals ?? 0
            let amountDecimal = BigDecimal(sign * amountInt,
                                           Int(clamping: precision))

            amount = formatter.string(
                from: amountDecimal,
                decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
                thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
                forcePlusSign: true)
            tokenSymbol = token?.symbol ?? ""
            tokenLogoURL = token?.logo?.absoluteString ?? ""
        }

        super.init(tx, safeInfo)

        if let date = date {
            self.date = date
            formattedDate = Self.dateFormatter.string(from: date)
        }
        if let status = status {
            self.status = status
        }

        if let hash = hash {
            self.hash = hash.description
        }
    }

    // typealiases for shorter source code line length
    fileprivate typealias Erc20Transfer = MethodRegistry.ERC20.Transfer
    fileprivate typealias Erc20TransferFrom = MethodRegistry.ERC20.TransferFrom
    fileprivate typealias Erc721SafeTransferFrom = MethodRegistry.ERC721.SafeTransferFrom
    fileprivate typealias Erc721SafeTransferFromData = MethodRegistry.ERC721.SafeTransferFromData

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

        } else if let data = tx.dataDecoded, let call = Erc721SafeTransferFromData(data: data) {
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

    static let erc20Methods: [SmartContractMethodCall.Type] = [MethodRegistry.ERC20.Transfer.self, MethodRegistry.ERC20.TransferFrom.self]
    static let erc721Methods: [SmartContractMethodCall.Type] = [MethodRegistry.ERC721.SafeTransferFrom.self, MethodRegistry.ERC721.SafeTransferFromData.self]
    static let transferMethods: [SmartContractMethodCall.Type] = erc20Methods + erc721Methods
    
    override class func viewModels(from tx: Transaction, info: SafeStatusRequest.Response) -> [TransactionViewModel] {
        var result = [TransactionViewModel]()

        // ether transaction
        if tx.data == nil && tx.operation == .call {
            let token = App.shared.tokenRegistry.token(address: AddressRegistry.ether)!
            let transferInfo = TransferInfo(ether: tx, info: info, token: token)
            result = [etherViewModel(transferInfo, tx, info)]

        // external transaction transferring something
        } else if tx.txType == .ethereum, let transfers = tx.transfers, !transfers.isEmpty {

            // multiple token transfers
            result = transfers.map { transfer in

                // token from the data itself
                if let tokenInfo = transfer.tokenInfo {
                    return tokenViewModel(Token(tokenInfo), transfer, tx, info)

                // token from list of known tokens
                } else if let tokenAddress = transfer.tokenAddress?.address, let token = App.shared.tokenRegistry.token(address: tokenAddress) {
                    return tokenViewModel(token, transfer, tx, info)

                // unknown token, treat as custom transaction
                } else if transfer.tokenAddress?.address != nil {
                    return customViewModel(transfer, tx, info)

                // nil token, i.e. ether
                } else {
                    return etherViewModel(transfer, tx, info)
                }
            }

        // safe-initiated transaction that is transferring some token
        } else if tx.txType == .multiSig, tx.operation == .call, let call = MethodRegistry.method(from: tx.dataDecoded, candidates: transferMethods) {

            let method = TransferMethod(call)
            let tokenAddress = tx.to?.address ?? AddressRegistry.ether

            // known token
            if let token = App.shared.tokenRegistry.token(address: tokenAddress) {
                result = [transferViewModel(method, token, tx, info)]

            // erc721 token (conforming to the token standard)
            } else if (try? ERC721(tokenAddress).supportsInterface(ERC721.Selectors.safeTransferFrom)) == true {
                result = [transferViewModel(method, Token(erc721: tokenAddress), tx, info)]

            // erc721 token type (guessing by the decoded data)
            } else if MethodRegistry.method(from: tx.dataDecoded, candidates: erc721Methods) != nil {
                result = [transferViewModel(method, Token(erc721: tokenAddress), tx, info)]

            // erc20 token (guessing by the decoded data)
            } else if MethodRegistry.method(from: tx.dataDecoded, candidates: erc20Methods) != nil {
                result = [transferViewModel(method, Token(erc20: tokenAddress), tx, info)]

            // should not come there because that means that erc20 and erc721 methods
            // were not decoded, which must be true, becuase the outer 'else if' condition
            // is true
            } else {
                assertionFailure("Should not get here")
                LogService.shared.error("Transfer transaction classification failed in safe:\(tx.safeAddress(info))")
            }
        } else {
            // custom transaction, do nothing
            result = []
        }
        return result
    }

    fileprivate class func tokenViewModel(_ token: Token, _ transfer: TransactionTransfer, _ tx: Transaction, _ info: SafeStatusRequest.Response) -> TransactionViewModel {
        if transfer.type != token.type {
            assertionFailure("Invalid combination of transfer type and tokenInfo type")
            LogService.shared.error("Transfer transaction has invalid transfer and tokenInfo combination in safe: \(tx.safeAddress(info))")
            // continuing to still display this transfer
        }
        let transferInfo: TransferInfo
        switch token.type {
        case .erc20:
            transferInfo = TransferInfo(erc20: transfer, tx: tx, info: info, token: token)
        case .erc721:
            transferInfo = TransferInfo(erc721: transfer, tx: tx, info: info, token: token)
        }
        return transferViewModel(transferInfo, tx, info)
    }

    class func transferViewModel(_ transfer: TransferInfo, _ tx: Transaction, _ info: SafeStatusRequest.Response) -> TransactionViewModel {
        // populate transfer from decoded data

        // incoming: to = safe, from =  not safe
        // outgoing: from = safe, to = any
        // custom: to = not safe, from = not safe -> custom tx inited from transfer!

        // create transaction transfer view model
        // if not incoming or outgoing, then it is a custom transfer transaction
        return .init()
    }

    class func transferViewModel(_ method: TransferMethod, _ token: Token,  _ tx: Transaction, _ info: SafeStatusRequest.Response) -> TransactionViewModel {
        let transferInfo: TransferInfo
        switch token.type {
        case .erc20:
            transferInfo = TransferInfo(erc20: method, tx: tx, info: info, token: token)
        case .erc721:
            transferInfo = TransferInfo(erc721: method, tx: tx, info: info, token: token)
        }
        return transferViewModel(transferInfo, tx, info)
    }

    class func customViewModel(_ transfer: TransactionTransfer, _ tx: Transaction, _ info: SafeStatusRequest.Response) -> TransactionViewModel {
        return .init()
    }

    class func customViewModel(_ transfer: TransferInfo, _ tx: Transaction, _ info: SafeStatusRequest.Response) -> TransactionViewModel {
        return .init()
    }

    fileprivate class func etherViewModel(_ transfer: TransactionTransfer, _ tx: Transaction, _ info: SafeStatusRequest.Response) -> TransactionViewModel {
        // ether
        let token = App.shared.tokenRegistry.token(address: AddressRegistry.ether)!

        if transfer.type != .ether {
            assertionFailure("Expected to see ether transfer")
            LogService.shared.error("Transfer transaction has invalid (not ether) transfer type: \(tx.safeAddress(info))")
            // continuing to still display this transfer
        }
        let transferInfo = TransferInfo(ether: transfer, tx: tx, info: info, token: token)
        return transferViewModel(transferInfo, tx, info)
    }

    fileprivate class func etherViewModel(_ transfer: TransferInfo, _ tx: Transaction, _ info: SafeStatusRequest.Response) -> TransactionViewModel {
        return transferViewModel(transfer, tx, info)
    }
}
