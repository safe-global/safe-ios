//
//  WCRegistryIntegrationTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 09.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class WCRegistryIntegrationTests: CoreDataTestCase {

    var service = WCRegistryService(url: App.configuration.walletConnect.registryURL, logger: MockLogger())

    func testWallets() throws {
        let exp = expectation(description: "Load Wallets")

        _ = service.asyncWallets(completion: { result in
            defer {
                exp.fulfill()
            }
            do {
                let registry = try result.get()
                XCTAssertFalse(registry.entries.isEmpty)
                if let entry = registry.entries.first {
                    print(entry)
                }
            } catch {
                XCTFail("Load wallets failed: \(error)")
            }
        })

        waitForExpectations(timeout: 60, handler: nil)
    }

    func testDapps() throws {
        let exp = expectation(description: "Load Wallets")

        _ = service.asyncDapps(completion: { result in
            defer {
                exp.fulfill()
            }
            do {
                let registry = try result.get()
                XCTAssertFalse(registry.entries.isEmpty)
                if let entry = registry.entries.first {
                    print(entry)
                }
            } catch {
                XCTFail("Load dapps failed: \(error)")
            }
        })

        waitForExpectations(timeout: 60, handler: nil)
    }

}
