//
//  EIP712TransactoinTransformer.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import Version

struct TDTypedData<Message: Codable>: Codable {
    var types: [TDObjectName: [TDMemberDescription]]
    var primaryType: TDObjectName
    var domain: TDDomain
    var message: Message
}

func TDTypes(from value: [String : [(name: String, type: String)]]) -> [TDObjectName: [TDMemberDescription]] {
    let result = Dictionary(
        uniqueKeysWithValues: value.map { (key, value) -> (TDObjectName, [TDMemberDescription]) in
            (key, value.map { (name, type) -> TDMemberDescription in
                TDMemberDescription(name: name, type: type)
            })
        }
    )
    return result
}

typealias TDObjectName = String
struct TDMemberDescription: Codable {
    var name: String
    var type: String
}

struct TDDomain: Codable {
    var name: String?
    var version: String?
    var chainId: String?
    var verifyingContract: String?
    var salt: String?
}

// version < 1.0.0: 'dataGas' is used
struct TDSafeTx_pre_1_0_0: Codable {
    var to: AddressString
    var value: UInt256String
    var data: DataString
    var operation: SCGModels.Operation
    var safeTxGas: UInt256String
    var dataGas: UInt256String
    var gasPrice: UInt256String
    var gasToken: AddressString
    var refundReceiver: AddressString
    var nonce: UInt256String
    
    static let typeName = "SafeTx"
    static let types = TDTypes(from: [
        typeName: [
            ("to", "address"),
            ("value", "uint256"),
            ("data", "bytes"),
            ("operation", "uint8"),
            ("safeTxGas", "uint256"),
            ("dataGas", "uint256"),
            ("gasPrice", "uint256"),
            ("gasToken", "address"),
            ("refundReceiver", "address"),
            ("nonce", "uint256"),
        ]
    ])
}

extension TDSafeTx_pre_1_0_0 {
    init(tx: Transaction) {
        to = tx.to
        value = tx.value
        data = tx.data ?? DataString(Data())
        operation = tx.operation
        safeTxGas = tx.safeTxGas
        dataGas = tx.baseGas
        gasPrice = tx.gasPrice
        gasToken = tx.gasToken
        refundReceiver = tx.refundReceiver
        nonce = tx.nonce
    }
}

// version >= 1.0.0: 'baseGas' is used
struct TDSafeTx: Codable {
    var to: AddressString
    var value: UInt256String
    var data: DataString
    var operation: SCGModels.Operation
    var safeTxGas: UInt256String
    var baseGas: UInt256String
    var gasPrice: UInt256String
    var gasToken: AddressString
    var refundReceiver: AddressString
    var nonce: UInt256String
    
    static let typeName = "SafeTx"
    static let types = TDTypes(from: [
        typeName: [
            ("to", "address"),
            ("value", "uint256"),
            ("data", "bytes"),
            ("operation", "uint8"),
            ("safeTxGas", "uint256"),
            ("baseGas", "uint256"),
            ("gasPrice", "uint256"),
            ("gasToken", "address"),
            ("refundReceiver", "address"),
            ("nonce", "uint256"),
        ]
    ])
}

extension TDSafeTx {
    init(tx: Transaction) {
        to = tx.to
        value = tx.value
        data = tx.data ?? DataString(Data())
        operation = tx.operation
        safeTxGas = tx.safeTxGas
        baseGas = tx.baseGas
        gasPrice = tx.gasPrice
        gasToken = tx.gasToken
        refundReceiver = tx.refundReceiver
        nonce = tx.nonce
    }
}

// version < 1.3.0
let TDEIP712Domain_pre_1_3_0 = TDTypes(from: [
    "EIP712Domain": [(name: "verifyingContract", type: "address")]
])

// version >= 1.3.0
let TDEIP712Domain = TDTypes(from: [
    "EIP712Domain": [
        (name: "chainId", type: "uint256"),
        (name: "verifyingContract", type: "address"),
    ]
])

class EIP712Transformer {
    // https://github.com/safe-global/safe-eth-py/blob/772a7da3a281c21931b8e5f01508a74cab7ecfb8/gnosis/safe/safe_tx.py#L126
    static func typedData(_ tx: Transaction) -> String {
        let safeAddress = tx.safe!
        let safeVersion = tx.safeVersion!
        
        let domainType: [TDObjectName: [TDMemberDescription]]
        let domain: TDDomain
        
        if safeVersion >= Version(1, 3, 0) {
            domainType = TDEIP712Domain
            domain = TDDomain(
                chainId: tx.chainId!,
                verifyingContract: safeAddress.description
            )
        } else {
            domainType = TDEIP712Domain_pre_1_3_0
            domain = TDDomain(verifyingContract: safeAddress.description)
        }
        
        if safeVersion >= Version(1, 0, 0) {
            let data = TDTypedData<TDSafeTx>(
                types: domainType.merging(TDSafeTx.types) { (current, _) in current },
                primaryType: TDSafeTx.typeName,
                domain: domain,
                message: TDSafeTx(tx: tx)
            )
            let result = try! String(data: JSONEncoder().encode(data), encoding: .utf8)!
            return result
        } else {
            let data = TDTypedData<TDSafeTx_pre_1_0_0>(
                types: domainType.merging(TDSafeTx_pre_1_0_0.types) { (current, _ ) in current },
                primaryType: TDSafeTx_pre_1_0_0.typeName,
                domain: domain,
                message: TDSafeTx_pre_1_0_0(tx: tx)
            )
            let result = try! String(data: JSONEncoder().encode(data), encoding: .utf8)!
            return result
        }
    }
}
