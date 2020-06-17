//
//  MethodSignatureTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 17.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class MethodSignatureTests: MethodRegistryTestCase {

    func testInit() {
        let empty = MethodRegistry.MethodSignature("empty")
        XCTAssertEqual(empty.name, "empty")
        XCTAssertEqual(empty.parameterTypes, [])

        let one = MethodRegistry.MethodSignature("test", "one")
        XCTAssertEqual(one.name, "test")
        XCTAssertEqual(one.parameterTypes, ["one"])

        let many = MethodRegistry.MethodSignature("many", "one", "two", "three")
        XCTAssertEqual(many.name, "many")
        XCTAssertEqual(many.parameterTypes, ["one", "two", "three"])
    }

    func testEquality() {
        let data = txData((
            "equality with method signature",
            "method", [
                ("one", "O", "1"),
                ("two", "T", "2"),
                ("three", "H", nil)
        ]))
        let sig = MethodRegistry.MethodSignature("method", "O", "T", "H")
        XCTAssertTrue(data == sig)
    }
}
