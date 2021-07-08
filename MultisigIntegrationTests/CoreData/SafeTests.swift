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
        let network1 = try makeNetwork(id: 1)
        let network2 = try makeNetwork(id: 2)

        Safe.create(address: "0x0000000000000000000000000000000000000000", name: "0", network: network1, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000001", name: "1", network: network1, selected: true)
        Safe.create(address: "0x0000000000000000000000000000000000000002", name: "2", network: network2, selected: false)

        var safesResult = try context.fetch(Safe.fetchRequest().all())
        var networksResult = try context.fetch(Network.fetchRequest().all())
        XCTAssertEqual(safesResult.count, 3)
        XCTAssertEqual(networksResult.count, 2)

        var safe = safesResult.first!
        Safe.remove(safe: safe)
        safesResult = try context.fetch(Safe.fetchRequest().all())
        networksResult = try context.fetch(Network.fetchRequest().all())
        XCTAssertEqual(safesResult.count, 2)
        XCTAssertEqual(networksResult.count, 2)

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
        let safe0 = createSafe(name: "1", address: "0x1")
        let safe1 = createSafe(name: "0", address: "0x0")
        let allSafes = try Safe.getAll()
        XCTAssertEqual(allSafes.count, 2)
        // should be sorted by creation date
        XCTAssertEqual(allSafes[0], safe0)
        XCTAssertEqual(allSafes[1], safe1)
    }

    func test_safeBy() throws {
        let safe = createSafe(name: "0", address: "0x0")
        createSafe(name: "1", address: "0x1")
        let result = Safe.by(address: "0x0", networkId: Network.ChainID.ethereumMainnet)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, safe)
    }

    func test_update() {
        let safe = createSafe(name: "0", address: Address.zero.checksummed)
        safe.update(name: "1")
        let result = Safe.by(address: Address.zero.checksummed, networkId: Network.ChainID.ethereumMainnet)
        XCTAssertEqual(result?.name, "1")
    }

    func test_select() throws {
        let testNetwork1 = try makeNetwork(id: 1)
        let testNetwork2 = try makeNetwork(id: 2)
        let testNetwork3 = try makeNetwork(id: 3)

        Safe.create(address: "0x0000000000000000000000000000000000000001", name: "1", network: testNetwork1, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000001", name: "2", network: testNetwork2, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000001", name: "3", network: testNetwork3, selected: true)

        Safe.select(address: "0x0000000000000000000000000000000000000001", networkId: 2)

        let result = try Safe.getSelected()!
        XCTAssertEqual(result.name, "2")
    }

    @discardableResult
    private func createSafe(name: String, address: String, network: Network = Network.mainnetChain()) -> Safe {
        let safe = Safe(context: context)
        safe.name = name
        safe.address = address
        safe.network = network
        try! context.save()
        return safe
    }

    private func makeNetwork(id: Int) throws -> Network {
        try Network.create(
            chainId: id,
            chainName: "Test",
            rpcUrl: URL(string: "https://rpc.com/")!,
            blockExplorerUrl: URL(string: "https://block.com/")!,
            ensRegistryAddress: "0x0000000000000000000000000000000000000001",
            currencyName: "Currency",
            currencySymbl: "CRY",
            currencyDecimals: 18,
            currencyLogo: URL(string: "https://example.com/crylogo.png")!,
            themeTextColor: "#ffffff",
            themeBackgroundColor: "#000000")
    }
}
