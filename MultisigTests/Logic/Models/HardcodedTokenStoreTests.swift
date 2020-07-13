//
//  HardcodedTokenStoreTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class HardcodedTokenStoreTests: XCTestCase {

    func testHardcoded() {
        let store = HardcodedTokenStore()
        let eth = store.token(address: AddressRegistry.ether)
        XCTAssertNotNil(eth)
        XCTAssertEqual(eth?.type, .erc20)
        XCTAssertEqual(eth?.decimals, 18)
        XCTAssertEqual(eth?.symbol, "ETH")
    }

}
