//
//  MethodRegistry.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

/// A namespace for value types representing methods of smart contracts
enum MethodRegistry {

    struct MethodSignature {
        var name: String
        var parameterTypes: [String]

        init(_ name: String, _ params: String...) {
            self.name = name
            self.parameterTypes = params
        }
    }

}

func == (lhs: TransactionData, rhs: MethodRegistry.MethodSignature) -> Bool {
    (lhs.method, lhs.parameters.map { $0.type }) == (rhs.name, rhs.parameterTypes)
}

protocol SmartContractMethodCall {
    static var signature: MethodRegistry.MethodSignature { get }
    init?(data: TransactionData)
}
