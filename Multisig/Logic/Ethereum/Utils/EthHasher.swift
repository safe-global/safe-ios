//
//  EthHasher.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import CryptoSwift

struct EthHasher {

    static func hash(_ msg: Data) -> Data {
        let result = SHA3(variant: .keccak256).calculate(for: Array(msg))
        return Data(result)
    }

    static func hash(_ msg: String) -> Data {
        hash(msg.data(using: .utf8)!)
    }
}
