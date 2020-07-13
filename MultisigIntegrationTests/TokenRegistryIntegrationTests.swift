//
//  TokenRegistryIntegrationTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class TokenRegistryIntegrationTests: XCTestCase {

    let registry = TokenRegistry()

    let cryptoKitties: Address = "0x16baF0dE678E52367adC69fD067E5eDd1D33e3bF"
    let chainLinkNotInBackend: Address = "0x01be23585060835e02b77ef475b0cc51aa1e0709"
    let notAToken: Address = "0x9bcd3162694994f67d49a8ead6e5a196c9dd2fd2"

    override func setUpWithError() throws {
        XTAssertEqual(App.configuration.app.network, .rinkeby,
                      "The test users rinkeby addresses")
    }

    func testLoad() {
        XCTAssertNil(registry[cryptoKitties])

        let exp = expectation(description: "Wait")
        registry.load {
            exp.fulfill()
        }

        XCTAssertNotNil(registry[cryptoKitties])
    }

    func testFetch() {
        var tokens = [Token?]()

        let exp = expectation(description: "Wait")
        DispatchQueue.global().async { [unowned self] in
            // hardcoded
            tokens.append(self.registry[AddressRegistry.ether])
            // pull from backend (AQER)
            tokens.append(self.registry[cryptoKitties])
            // same token, cached
            tokens.append(self.registry[cryptoKitties])
            // pull from blockchain (LINK)
            tokens.append(self.registry[chainLinkNotInBackend])
            // not a token -- should be recognized as ERC20 (this is a fallback logic)
            tokens.append(self.registry[notAToken])
            exp.fulfill()
        }
        waitForExpectations(timeout: 3)

        XCTAssertEqual(tokens.compactMap { $0 }.count, 5)
    }
}
