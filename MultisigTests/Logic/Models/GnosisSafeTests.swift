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
    let safe = GnosisSafe()

    func testSupportedVersions() {
        let supported: [String] = ["1.0.0", "1.1.0", "1.2.3"]
        let notSupported: [String] = ["0.1.0", "2.0.1"]

        for v in supported {
            XCTAssertTrue(safe.isSupported(v), "Expected to support \(v)")
        }

        for v in notSupported {
            XCTAssertFalse(safe.isSupported(v), "Expected NOT to support \(v)")
        }
    }
}
