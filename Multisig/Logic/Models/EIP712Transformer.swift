//
//  EIP712TransactoinTransformer.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import Version

class EIP712Transformer {
    static func typedDataString(from transaction: Transaction) -> String {
        guard let safe = transaction.safe else { preconditionFailure("safe is required for typedData") }

        var safeDomain = EIP712Domain(
            verifyingContract: safe.description
        )
        var eip712Description = EIP712Domain.eip712Description

        // Reference: https://github.com/gnosis/gnosis-py/blob/772a7da3a281c21931b8e5f01508a74cab7ecfb8/gnosis/safe/safe_tx.py#L169
        if transaction.safeVersion! >= Version("1.3.0")! {
            safeDomain.chainId = transaction.chainId
            eip712Description.members.insert(.init(name: "chainId", type: "uint256"), at: 0)
        }

        let typedData = EIP712TypedData<Transaction>(
            types: [
                eip712Description,
                Transaction.eip712Description
            ],
            primaryType: Transaction.eip712Description.name,
            domain: safeDomain,
            message: transaction
        )

        return try! JSONEncoder().encode(typedData).makeString()
    }
}

extension Transaction: EIP712Convertible {
    static var eip712Description: EIP712TypeDescription {
        .init(
            name: "SafeTx",
            members: [
                .init(name: "to", type: "address"),
                .init(name: "value", type: "uint256"),
                .init(name: "data", type: "bytes"),
                .init(name: "operation", type: "uint8"),
                .init(name: "safeTxGas", type: "uint256"),
                .init(name: "baseGas", type: "uint256"),
                .init(name: "gasPrice", type: "uint256"),
                .init(name: "gasToken", type: "address"),
                .init(name: "refundReceiver", type: "address"),
                .init(name: "nonce", type: "uint256")
            ]
        )
    }
}

struct EIP712MemberDescription: Encodable {
    var name: String
    var type: String
}

struct EIP712TypeDescription {
    var name: String
    var members: [EIP712MemberDescription]
}

extension EIP712TypeDescription: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(members)
    }
}

protocol EIP712Convertible {
    static var eip712Description: EIP712TypeDescription { get }
}

struct EIP712TypedData<T: Encodable & EIP712Convertible> {
    var types: [EIP712TypeDescription]
    var primaryType: String
    var domain: EIP712Domain
    var message: T
}

extension EIP712TypedData: Encodable {
    enum Key: String, CodingKey { case types, primaryType, domain, message }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        let encodedTypes: [String: EIP712TypeDescription] = .init(uniqueKeysWithValues: types.map({  ($0.name, $0) }))
        try container.encode(encodedTypes, forKey: .types)
        try container.encode(primaryType, forKey: .primaryType)
        try container.encode(domain, forKey: .domain)
        try container.encode(message, forKey: .message)
    }
}

struct EIP712Domain: Encodable {
    var verifyingContract: String
    var chainId: String?
}

extension EIP712Domain: EIP712Convertible {
    static var eip712Description: EIP712TypeDescription {
        .init(
            name: "EIP712Domain",
            members: [
                .init(name: "verifyingContract", type: "address"),
            ])
    }
}
