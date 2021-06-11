//
//  EIP712TransactoinTransformer.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class EIP712Transformer {
    static func typedDataString(from transaction: Transaction) -> String {
        guard let safe = transaction.safe else { preconditionFailure("safe is required for typedData") }

        let safeDomain = EIP712Domain(
            verifyingContract: safe.description
        )

        let typedData = EIP712TypedData<Transaction>(
            types: [
                EIP712Domain.eip712Description,
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
