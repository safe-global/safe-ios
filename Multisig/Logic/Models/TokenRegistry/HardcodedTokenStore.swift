//
//  HardcodedTokenStore.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct HardcodedTokenStore {

    private var store = InMemoryTokenStore()

    init() {
        store.add(
            Token(type: .erc20,
                  address: AddressRegistry.ether,
                  logo: BackendTokenStore.logo(AddressRegistry.ether),
                  name: "Ether",
                  symbol: "ETH",
                  decimals: 18)
        )
    }

    func token(address: Address) -> Token? {
        store.token(address: address)
    }

    mutating func add(_ token: Token) {
        // no-op
    }

}
