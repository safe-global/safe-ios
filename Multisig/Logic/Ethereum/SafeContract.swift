//
//  SafeContract.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class SafeContract: Contract {
    func nonce() throws -> UInt256 {
        try decodeUInt(invoke("nonce()"))
    }
}
