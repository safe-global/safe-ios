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
        var mainnet = Network.mainnetChain()

        Safe.create(address: "0x0000000000000000000000000000000000000000", version: "1.2.0", name: "0", network: mainnet, selected: false)

        var safe = try context.fetch(Safe.fetchRequest().all()).first!
        safe.network = nil

        Network.removeAll()

        let result = try context.fetch(Safe.fetchRequest().all())
        XCTAssertEqual(result.count, 1, "Safe should not be removed")

        safe = result.first!
        XCTAssertNil(safe.network)

        ChainManager.migrateOldSafes()

        mainnet = Network.mainnetChain()
        XCTAssertEqual(safe.network, mainnet)
        XCTAssertEqual(mainnet.chainId, Network.ChainID.ethereumMainnet)
        XCTAssertEqual(mainnet.nativeCurrency?.symbol, "ETH")
    }
}
