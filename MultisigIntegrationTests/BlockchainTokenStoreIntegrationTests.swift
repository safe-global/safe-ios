//
//  BlockchainTokenStoreIntegrationTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class BlockchainTokenStoreIntegrationTests: RinkebyTestCase {

    let store = BlockchainTokenStore()

    func testERC20Token() {
        let aqer: Address = "0x63704b63ac04f3a173dfe677c7e3d330c347cd88"
        let token = store.token(address: aqer)
        XCTAssertNotNil(token)
        XCTAssertEqual(token?.type, .erc20)
        XCTAssertEqual(token?.symbol, "AQER")
        XCTAssertEqual(token?.decimals, 18)
    }

    // NOTE: couldn't find an erc721 token that implements ERC721 completely.

}
