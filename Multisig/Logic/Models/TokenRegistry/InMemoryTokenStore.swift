//
//  InMemoryTokenStore.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct InMemoryTokenStore {

    private var items: [Address: Token] = [:]

    func token(address: Address) -> Token? {
        items[address]
    }

    mutating func add(_ token: Token) {
        items[token.address] = token
    }

}
