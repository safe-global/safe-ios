//
//  SafeNetworkMigrationTests.swift
//  MultisigIntegrationTests
//
//  Created by Andrey Scherbovich on 28.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class SafeNetworkMigrationTests: CoreDataTestCase {
    func test_migratingOldSafes() throws {
        var mainnet = Chain.mainnetChain()

        Safe.create(address: "0x0000000000000000000000000000000000000000", version: "1.2.0", name: "0", chain: mainnet, selected: false)

        var safe = try context.fetch(Safe.fetchRequest().all()).first!
        safe.chain = nil

        Chain.removeAll()

        let result = try context.fetch(Safe.fetchRequest().all())
        XCTAssertEqual(result.count, 1, "Safe should not be removed")

        safe = result.first!
        XCTAssertNil(safe.chain)

        ChainManager.migrateOldSafes()

        mainnet = Chain.mainnetChain()
        XCTAssertEqual(safe.chain, mainnet)
        XCTAssertEqual(mainnet.id, Chain.ChainID.ethereumMainnet)
        XCTAssertEqual(mainnet.nativeCurrency?.symbol, "ETH")
    }
}
