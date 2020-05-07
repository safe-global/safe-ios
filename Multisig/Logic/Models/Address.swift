//
//  Address.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Web3
import BigInt

typealias Address = EthereumAddress

extension Address.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .addressMalformed:
            return "The address is malformed. Please provide an Ethereum address."
        case .checksumWrong:
            return "The address is typed incorrectly. Please double-check it."
        }
    }
}

extension Address {

    static let zero = try! Address(Bytes(repeating: 0, count: 20))

    var isZero: Bool {
        self == .zero
    }

}

extension Address {

    init(_ value: BigUInt) {
        let data = Data(ethHex: String(value, radix: 16)).endTruncated(to: 20).leftPadded(to: 20)
        try! self.init(hex: "0x" + data.toHexString(), eip55: false)
    }

    init?(_ value: String) {
        try? self.init(hex: value, eip55: false)
    }
}
