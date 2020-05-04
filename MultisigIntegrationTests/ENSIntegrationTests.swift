//
//  ENSIntegrationTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 04.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class ENSIntegrationTests: XCTestCase {

    let ensService = App.shared.ens

    func test_forwardResolution() {
        XCTAssertNoThrow(try {
            let address = try ensService.address(for: "gnosissafeios.test")
            XCTAssertEqual(address, try! Address(hex: "0x2333b4CC1F89a0B4C43e9e733123C124aAE977EE", eip55: false))
        }())
    }

    // the resolver is expired.
    func disabled_test_reverseResolution() {
        XCTAssertNoThrow(try {
            let name = try ensService.name(for: Address(hex: "0x2333b4CC1F89a0B4C43e9e733123C124aAE977EE", eip55: false))
            XCTAssertEqual(name, "gnosissafeios.test")
        }())
    }

}
