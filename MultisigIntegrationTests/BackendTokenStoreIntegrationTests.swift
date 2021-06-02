//
//  BackendTokenStoreIntegrationTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class BackendTokenStoreIntegrationTests: RinkebyTestCase {
    let store = BackendTokenStore()

    func testTokens() {
        let exp = expectation(description: "Wait")
        var tokens: [Token] = []
        DispatchQueue.global().async { [unowned self] in
            tokens = self.store.tokens()
            exp.fulfill()
        }
        waitForExpectations(timeout: 20)

        XCTAssertFalse(tokens.isEmpty)
    }

    func testToken() {
        let expectedTokens: [Address] = [
            "0x16baF0dE678E52367adC69fD067E5eDd1D33e3bF",
            "0xFFadE30f03a17581362171982F95657C1306a68f",
            "0x63704B63Ac04f3a173Dfe677C7e3D330c347CD88"
        ]

        let exp = expectation(description: "Wait")
        var tokens: [Token] = []
        DispatchQueue.global().async { [unowned self] in
            tokens = expectedTokens.compactMap { self.store.token(address: $0) }
            exp.fulfill()
        }
        waitForExpectations(timeout: 10)

        let actualTokens = tokens.map { $0.address }
        XCTAssertEqual(expectedTokens, actualTokens, "Some tokens are unknown")
    }

}
