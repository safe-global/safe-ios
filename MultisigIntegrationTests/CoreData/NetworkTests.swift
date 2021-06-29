//
//  NetworkTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 28.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import CoreData

class NetworkTests: CoreDataTestCase {

    // NOTE: couldn't test cases when NSManagedObjectContext fails and thus other methods throw or work correctly
    // because couldn't subclass it. Affected methods: `count`, `all`

    // MARK: count
    func test_count_whenNoNetworks_returns0() {
        // nothing to set up, no networks exist by default.

        XCTAssertEqual(Network.count, 0)
    }

    func test_count_whenMultipleExists_thenReturnsCorrectCount() throws {
        _ = try makeNetwork(id: 1)
        _ = try makeNetwork(id: 2)
        _ = try makeNetwork(id: 3)

        XCTAssertEqual(Network.count, 3)
    }

    // all
        // when no networks, returns empty
        // when some networks, returns all sorted by network id

    // exists(id)
        // when no networks, returns false
        // when not found, returns false
        // when found, returns true

    // by(id)
        // when empty, returns nil
        // when not found, returns nil
        // when found, returns network

    // MARK: create(params)

    func test_create_whenCreatedThenHasCorrectParameters() throws {
        let network = try makeNetwork(id: 1)

        // assert
        XCTAssertEqual(network.chainId, 1)
        XCTAssertEqual(network.id, 1)
        XCTAssertEqual(network.chainName, "Test")
        XCTAssertEqual(network.rpcUrl, URL(string: "https://rpc.com/")!)
        XCTAssertEqual(network.blockExplorerUrl, URL(string: "https://block.com/")!)
        XCTAssertEqual(network.nativeCurrency?.name, "Currency")
        XCTAssertEqual(network.nativeCurrency?.symbol, "CRY")
        XCTAssertEqual(network.nativeCurrency?.decimals, 18)
        XCTAssertEqual(network.theme?.textColor, "#ffffff")
        XCTAssertEqual(network.theme?.backgroundColor, "#000000")
    }

    func test_create_whenCreatedWithDuplicateChainId_thenThrows() throws {
        _ = try makeNetwork(id: 1)

        XCTAssertThrowsError(try makeNetwork(id: 1))
    }

    // update(from networkInfo)
        // when different chain id then throws
        // when set the params, then updates with appropriate params
        // when no theme exists, creates it
        // when no native currency attached, creates it

    // createOrUpdate(info)
        // when no such network id, then creates it
        // when exists with network id, then overwrites it

    // create(scg network)
        // when created, then creates with parameters

    // updateIfExist(scg network)
        // when not exists, then nothing happens (existing is the same, no new added)
        // when same id, then overwrites it

    // remove(network)
        // when removes then removed
        // when removes, then removes all safes in the network

    //func test_removingNetworkDeletesSafe() throws {
    //        let mainnet = Network.mainnetChain()
    //        Safe.create(address: "0x0000000000000000000000000000000000000000", name: "0", network: mainnet, selected: false)
    //        Safe.create(address: "0x0000000000000000000000000000000000000001", name: "1", network: mainnet)
    //        var result = try context.fetch(Safe.fetchRequest().all())
    //        XCTAssertEqual(result.count, 2)
    //        try Network.removeAll()
    //        result = try context.fetch(Safe.fetchRequest().all())
    //        XCTAssertEqual(result.count, 0)
    //    }

    // removeAll()
        // when empty then ok
        // when some, then removes all

    // mainnetChain()
        // when not found by chain, then creates new one
        // when existing, then returns it.

    // authenticatedRpcUrl
        // given the rpcURL, adds the path parameter

    // MARK: Utility

    func makeNetwork(id: Int) throws -> Network {
        try Network.create(
            chainId: id,
            chainName: "Test",
            rpcUrl: URL(string: "https://rpc.com/")!,
            blockExplorerUrl: URL(string: "https://block.com/")!,
            currencyName: "Currency",
            currencySymbl: "CRY",
            currencyDecimals: 18,
            themeTextColor: "#ffffff",
            themeBackgroundColor: "#000000")
    }

    func test_networkSafes() throws {
        let network1 = try makeNetwork(id: 1)
        let network3 = try makeNetwork(id: 3)
        let network2 = try makeNetwork(id: 2)

        Safe.create(address: "0x0000000000000000000000000000000000000000", name: "00", network: network1, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000001", name: "01", network: network1, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000011", name: "11", network: network3, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000010", name: "10", network: network3, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000020", name: "20", network: network2, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000021", name: "21", network: network2, selected: true)
        Safe.create(address: "0x0000000000000000000000000000000000000022", name: "22", network: network2, selected: false)

        let networkSafes = Network.networkSafes()

        XCTAssertEqual(networkSafes.count, 3)

        XCTAssertEqual(networkSafes[0].network, network2)
        XCTAssertEqual(networkSafes[0].safes.count, 3)
        XCTAssertEqual(networkSafes[0].safes[0].name, "21")
        XCTAssertEqual(networkSafes[0].safes[1].name, "20")
        XCTAssertEqual(networkSafes[0].safes[2].name, "22")

        XCTAssertEqual(networkSafes[1].network, network1)
        XCTAssertEqual(networkSafes[1].safes.count, 2)
        XCTAssertEqual(networkSafes[1].safes[0].name, "00")
        XCTAssertEqual(networkSafes[1].safes[1].name, "01")

        XCTAssertEqual(networkSafes[2].network, network3)
        XCTAssertEqual(networkSafes[2].safes.count, 2)
        XCTAssertEqual(networkSafes[2].safes[0].name, "11")
        XCTAssertEqual(networkSafes[2].safes[1].name, "10")
    }
}

// when created a safe, then the count of safes = 1, count of chain = 1, token, theme = 1

