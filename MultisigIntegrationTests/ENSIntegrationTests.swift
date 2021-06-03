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

    let ensService = App.shared.blockchainDomainManager.ens

    func test_forwardResolution() {
        XCTAssertNoThrow(try {
            let address = try ensService.address(for: "gnosissafeios.test")
            XCTAssertEqual(address, "0x2333b4CC1F89a0B4C43e9e733123C124aAE977EE")
        }())
    }

    // the resolver is expired.
    func disabled_test_reverseResolution() {
        XCTAssertNoThrow(try {
            let name = try ensService.name(for: "0x2333b4CC1F89a0B4C43e9e733123C124aAE977EE")
            XCTAssertEqual(name, "gnosissafeios.test")
        }())
    }

}
