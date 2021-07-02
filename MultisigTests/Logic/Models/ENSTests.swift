//
//  ENSTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 04.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class ENSTests: XCTestCase {
    func test_namehash() {
        let service = ENS(registryAddress: .zero, rpcURL: URL(string: "https://example.com")!)
        XCTAssertEqual(service.namehash(""),
                       Data(hex: "0x0000000000000000000000000000000000000000000000000000000000000000"))
        XCTAssertEqual(service.namehash("eth"),
        Data(hex: "0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae"))
        XCTAssertEqual(service.namehash("foo.eth"),
        Data(hex: "0xde9b09fd7c5f901e23a3f19fecc54828e9c848539801e86591bd9801b019f84f"))
    }
}
