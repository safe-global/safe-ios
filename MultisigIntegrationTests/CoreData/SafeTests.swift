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
    func test_removeSafe() throws {
        Safe.create(address: "0x0000000000000000000000000000000000000000", name: "0", selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000001", name: "1")
        Safe.create(address: "0x0000000000000000000000000000000000000002", name: "2", selected: false)

        var result = try context.fetch(Safe.fetchRequest().all())
        XCTAssertEqual(result.count, 3)

        var safe = result.first!
        Safe.remove(safe: safe)
        result = try context.fetch(Safe.fetchRequest().all())
        XCTAssertEqual(result.count, 2)

        safe = result.first!
        XCTAssertTrue(safe.isSelected)
        Safe.remove(safe: safe)
        result = try context.fetch(Safe.fetchRequest().all())
        XCTAssertEqual(result.count, 1)

        safe = result.first!
        XCTAssertNotNil(safe.selection)
        Safe.remove(safe: safe)
        result = try context.fetch(Safe.fetchRequest().all())
        XCTAssertEqual(result.count, 0)
    }

    func test_allSafes() throws {
        let safe0 = createSafe(name: "1")
        let safe1 = createSafe(name: "0")
        let result = try context.fetch(Safe.fetchRequest().all())
        XCTAssertEqual(result.count, 2)
        // should be sorted by creation date
        XCTAssertEqual(result[0], safe0)
        XCTAssertEqual(result[1], safe1)
    }

    func test_safeBy() throws {
        let safe = createSafe(name: "0")
        safe.address = "0x0"
        createSafe(name: "1")
        let result = try context.fetch(Safe.fetchRequest().by(address: "0x0"))
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
