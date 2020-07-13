//
//  InMemoryTokenStoreTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class InMemoryTokenStoreTests: XCTestCase {

    func testAdd() {
        var store = InMemoryTokenStore()
        // empty
        XCTAssertNil(store.token(address: .zero))

        // add one
        let token0 = Token(type: .erc20,
                           address: .zero,
                           logo: nil,
                           name: "Zero",
                           symbol: "ZR0",
                           decimals: 1)
        store.add(token0)
        XCTAssertEqual(store.token(address: .zero), token0)

        // add another tokenm
        let token1 = Token(type: .erc721,
                           address: Address("0x" + String(repeating: "1", count: 40))!,
                           logo: nil,
                           name: "One",
                           symbol: "111",
                           decimals: 1)
        store.add(token1)
        XCTAssertEqual(store.token(address: token1.address), token1)

        // replace existing token
        let token2 = Token(type: .erc721,
                           address: .zero,
                           logo: nil,
                           name: "Two",
                           symbol: "222",
                           decimals: 1)
        store.add(token2)
        XCTAssertEqual(store.token(address: .zero), token2)
    }

}
