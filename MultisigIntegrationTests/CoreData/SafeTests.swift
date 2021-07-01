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
        let mainnet = Network.mainnetChain()

        Safe.create(address: "0x0000000000000000000000000000000000000000", name: "0", network: mainnet, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000001", name: "1", network: mainnet)
        Safe.create(address: "0x0000000000000000000000000000000000000002", name: "2", network: mainnet, selected: false)

        var safesResult = try context.fetch(Safe.fetchRequest().all())
        var networksResult = try context.fetch(Network.fetchRequest().all())
        XCTAssertEqual(safesResult.count, 3)
        XCTAssertEqual(networksResult.count, 1)

        var safe = safesResult.first!
        Safe.remove(safe: safe)
        safesResult = try context.fetch(Safe.fetchRequest().all())
        networksResult = try context.fetch(Network.fetchRequest().all())
        XCTAssertEqual(safesResult.count, 2)
        XCTAssertEqual(networksResult.count, 1)

        safe = safesResult.first!
        XCTAssertTrue(safe.isSelected)
        Safe.remove(safe: safe)
        safesResult = try context.fetch(Safe.fetchRequest().all())
        networksResult = try context.fetch(Network.fetchRequest().all())
        XCTAssertEqual(safesResult.count, 1)
        XCTAssertEqual(networksResult.count, 1)

        safe = safesResult.first!
        XCTAssertNotNil(safe.selection)
        Safe.remove(safe: safe)
        safesResult = try context.fetch(Safe.fetchRequest().all())
        networksResult = try context.fetch(Network.fetchRequest().all())
        XCTAssertEqual(safesResult.count, 0)
        XCTAssertEqual(networksResult.count, 0)
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
        let result = Safe.by(address: "0x0")
        XCTAssertNotNil(result)
        XCTAssertEqual(result, safe)
    }

    @discardableResult
    private func createSafe(name: String) -> Safe {
        let safe = Safe(context: context)
        safe.name = name
        return safe
    }
}
