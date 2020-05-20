//
//  GnosisSafeTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 20.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class GnosisSafeTests: XCTestCase {

    let someAddress = Address("0x4995D78E5a672CC035929822E97EAcEB4464f97A")!
    let safe = GnosisSafe()

    func testContractVersions() {
        XCTAssertEqual(safe.version(masterCopy: Address.zero), .unknown)
        XCTAssertEqual(safe.version(masterCopy: someAddress), .unknown)

        let oldVersion = safe.versions.first!
        XCTAssertEqual(safe.version(masterCopy: oldVersion.masterCopy), .upgradeAvailable(oldVersion.version))

        let newestVersion = safe.versions.last!
        XCTAssertEqual(safe.version(masterCopy: newestVersion.masterCopy), .upToDate(newestVersion.version))
    }

    func testSingleVersionsArray() {
        safe.versions = [(someAddress, "0.1.0")]
        let singleVersion = safe.versions.first!
        XCTAssertEqual(safe.version(masterCopy: singleVersion.masterCopy), .upToDate(singleVersion.version))
    }

    func testEmpty() {
        safe.versions = []
        XCTAssertEqual(safe.version(masterCopy: someAddress), .unknown)
    }

}
