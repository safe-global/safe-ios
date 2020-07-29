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
        XCTAssertEqual(App.configuration.app.network, .rinkeby,
                      "The test users rinkeby addresses")
    }

    func testLoad() {
        let exp = expectation(description: "Wait")
        registry.load {
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)

        let sema = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {

            XCTAssertNotNil(self.registry["0x2FDFfE9Cad323d3922195292E8806987B1fc1AAD"])
            sema.signal()
        }
        sema.wait()
    }

    func testFetch() {
        var tokens = [Token?]()

        let exp = expectation(description: "Wait")
        DispatchQueue.global().async { [unowned self] in
            tokens.append(self.registry[.ether])
            tokens.append(self.registry[self.cryptoKitties])
            let notInBackend = self.registry[self.chainLinkNotInBackend]
            tokens.append(notInBackend)
            XCTAssertNotNil(notInBackend)

            // not a token -- should not be added
            let shouldBeNil = self.registry[self.notAToken]
            XCTAssertNil(shouldBeNil)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3)

        XCTAssertEqual(tokens.compactMap { $0 }.count, 3)
    }
}
