//
//  Address.swift
//  MultisigTests
//
//  Created by Moaaz on 5/22/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class AddressTests: XCTestCase {

    func test_isERC681() throws {
        var addressText = "0x71592E6Cbe7779D480C1D029e70904041F8f602A"
        var address = try? Address.addressWithPrefix(text: addressText)
        XCTAssertNotNil(address)
        XCTAssertNil(address?.prefix)

        addressText = "ethereum:pay-0x71592E6Cbe7779D480C1D029e70904041F8f602A"
        address = try? Address.addressWithPrefix(text: addressText)
        XCTAssertNotNil(address)
        XCTAssertNil(address?.prefix)

        addressText = "eth:0x71592E6Cbe7779D480C1D029e70904041F8f602A"
        address = try? Address.addressWithPrefix(text: addressText)
        XCTAssertNotNil(address)
        XCTAssertNotNil(address?.prefix)
    }

}
