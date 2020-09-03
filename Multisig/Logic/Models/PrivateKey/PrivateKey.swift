//
//  PrivateKey.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 03.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3



struct PrivateKey {

    private var _store: EthereumPrivateKey

    init(mnemonic: [String], pathIndex: Int) throws {
        try _store = EthereumPrivateKey(hexPrivateKey: "")
    }

}
