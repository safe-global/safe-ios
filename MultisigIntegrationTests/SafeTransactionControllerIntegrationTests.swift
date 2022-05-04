//
//  SafeTransactionControllerIntegrationTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 04.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import JsonRpc2

class SafeTransactionControllerIntegrationTests: XCTestCase {

    func testGetOwners() throws {
        let safe: Address = "0x1230B3d59858296A31053C1b8562Ecf89A2f888b"

        let exp = expectation(description: "get owners")

        SafeTransactionController.shared.getOwners(safe: safe, chain: Chain.mainnetChain()) { result in
            do {
                let addresses = try result.get()
                print(addresses)
            } catch {
                XCTFail("Failed: \(error)")
            }

            exp.fulfill()
        }

        waitForExpectations(timeout: 15)
    }

}
