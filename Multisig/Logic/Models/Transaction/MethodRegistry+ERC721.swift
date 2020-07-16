//
//  MethodRegistry+ERC721.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension MethodRegistry {

    enum ERC721 {

        struct SafeTransferFrom: SmartContractMethodCall {
            static let signature = MethodSignature("safeTransferFrom", "address", "address", "uint256")
            let from: Address
            let to: Address
            let tokenId: UInt256

            init?(data: TransactionData) {
                guard data == Self.signature,
                    let from = data.parameters[0].addressValue,
                    let to = data.parameters[1].addressValue,
                    let tokenId = data.parameters[2].uint256Value else {
                        return nil
                }
                (self.from, self.to, self.tokenId) = (from, to, tokenId)
            }
        }

        struct SafeTransferFromData: SmartContractMethodCall {
            static let signature = MethodSignature("safeTransferFrom", "address", "address", "uint256", "bytes")
            let from: Address
            let to: Address
            let tokenId: UInt256
            let data: Data

            init?(data: TransactionData) {
                guard data == Self.signature,
                    let from = data.parameters[0].addressValue,
                    let to = data.parameters[1].addressValue,
                    let tokenId = data.parameters[2].uint256Value,
                    let data = data.parameters[3].bytesValue else {
                        return nil
                }
                (self.from, self.to, self.tokenId, self.data) = (from, to, tokenId, data)
            }
        }

        #warning("TODO: tx.contractInfo.type == ContractInfoType.ERC721")
        static func isValid(_ tx: Transaction) -> Bool {
            tx.operation == .call &&
                tx.dataDecoded != nil &&
                (SafeTransferFrom(data: tx.dataDecoded!) != nil ||
                    SafeTransferFromData(data: tx.dataDecoded!) != nil)
        }

    }

    private static let transferMethods: [SmartContractMethodCall.Type] = [
        ERC20.Transfer.self,
        ERC20.TransferFrom.self,
        ERC721.SafeTransferFrom.self,
        ERC721.SafeTransferFrom.self
    ]
    static func transferMethod(_ data: TransactionData?) -> SmartContractMethodCall? {
        MethodRegistry.method(from: data, candidates: transferMethods)
    }
}

struct TransferMethod {
    var from: Address?
    var to: Address
    var amount: UInt256
}

extension TransferMethod {

    init(_ t: SmartContractMethodCall) {
        if let t = t as? MethodRegistry.ERC721.SafeTransferFromData {
            self.init(t)
        } else if let t = t as? MethodRegistry.ERC721.SafeTransferFrom {
            self.init(t)
        } else if let t = t as? MethodRegistry.ERC20.TransferFrom {
            self.init(t)
        } else if let t = t as? MethodRegistry.ERC20.Transfer {
            self.init(t)
        } else {
            fatalError("Unexpected type of the method call")
        }
    }

    init(_ t: MethodRegistry.ERC721.SafeTransferFromData) {
        from = t.from
        to = t.to
        amount = 1
    }

    init(_ t: MethodRegistry.ERC721.SafeTransferFrom) {
        from = t.from
        to = t.to
        amount = 1
    }

    init(_ t: MethodRegistry.ERC20.TransferFrom) {
        from = t.from
        to = t.to
        amount = t.amount
    }

    init(_ t: MethodRegistry.ERC20.Transfer) {
        from = nil
        to = t.to
        amount = t.amount
    }

}

struct TransferInfo {
    var safe, from, to: Address
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
            safe: tx.safeAddress(info),
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
            safe: tx.safeAddress(info),
            from: transfer.from.address,
            to: transfer.to.address,
            amount: transfer.value?.value ?? 0,
            token: token)
    }

    init(erc20 method: TransferMethod,  tx: Transaction, info: SafeInfo, token: Token) {
        self.init(
            safe: tx.safeAddress(info),
            from: method.from ?? tx.safeAddress(info),
            to: method.to,
            amount: method.amount,
            token: token)
    }

    init(erc721 transfer: TransactionTransfer, tx: Transaction, info: SafeInfo, token: Token) {
        self.init(
            safe: tx.safeAddress(info),
            from: transfer.from.address,
            to: transfer.to.address,
            amount: 1,
            token: token)
    }

    init(erc721 method: TransferMethod,  tx: Transaction, info: SafeInfo, token: Token) {
        self.init(
        safe: tx.safeAddress(info),
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
