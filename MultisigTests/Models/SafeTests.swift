//
//  SafeTests.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 21.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class SafeTests: CoreDataTestCase {
    func test_allSafes() throws {
        let safe0 = createSafe(name: "1")
        let safe1 = createSafe(name: "0")
        let result = try context.fetch(Safe.allSafes())
        XCTAssertEqual(result.count, 2)
        // should be sorted by creation date
        XCTAssertEqual(result[0], safe0)
        XCTAssertEqual(result[1], safe1)
    }

    func test_safeBy() throws {
        let safe = createSafe(name: "0")
        safe.address = "0x0"
        createSafe(name: "1")
        let result = try context.fetch(Safe.by(address: "0x0"))
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0], safe)
    }

    @discardableResult
    private func createSafe(name: String) -> Safe {
        let safe = Safe(context: context)
        safe.name = name
        return safe
    }
}
