//
//  DisplayURLTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 15.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class DisplayURLTests: XCTestCase {

    func testDisplayURL() {
        let url = URL(string: "https://user:password@host.com:123/path/APIKEY?queryItem")!
        let expected = URL(string: "https://host.com:123")!
        XCTAssertEqual(DisplayURL(url).value, expected)
    }

}
