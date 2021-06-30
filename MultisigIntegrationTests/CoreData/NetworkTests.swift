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
        XCTAssertEqual(Network.count, 0)
    }

    func test_count_whenMultipleExists_thenReturnsCorrectCount() throws {
        _ = try makeNetwork(id: 1)
        _ = try makeNetwork(id: 2)
        _ = try makeNetwork(id: 3)

        XCTAssertEqual(Network.count, 3)
    }

    func test_all() throws {
        XCTAssertEqual(Network.count, 0)
        let network0 = try makeNetwork(id: 1)
        let network1 = try makeNetwork(id: 2)
        let network2 = try makeNetwork(id: 3)

        let networks = Network.all
        XCTAssertEqual(networks.count, 3)
        XCTAssertEqual(network0, networks[0])
        XCTAssertEqual(network1, networks[1])
        XCTAssertEqual(network2, networks[2])
    }

    func test_exists() {
        XCTAssertFalse(try Network.exists(1))
        _ = try? makeNetwork(id: 1)

        XCTAssertFalse(try Network.exists(2))
        XCTAssertTrue(try Network.exists(1))
    }

    func test_by() {
        var network = Network.by(1)
        XCTAssertNil(network)
        _ = try? makeNetwork(id: 1)

        network = Network.by(2)
        XCTAssertNil(network)

        network = Network.by(1)
        XCTAssertNotNil(network)
    }

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

    func test_update() throws {
        let network = Network.mainnetChain()

        // updating with different chain id
        var networkInfo = makeTestNetworkInfo(id: Int(network.chainId) + 1)
        XCTAssertThrowsError(
            try network.update(from: networkInfo)
        )

        networkInfo = makeTestNetworkInfo(id: Int(network.chainId))

        // updating with same chain id
        XCTAssertNoThrow(
            try network.update(from: networkInfo)
        )

        XCTAssertEqual(network.id, networkInfo.chainId)
        XCTAssertEqual(network.chainName, networkInfo.chainName)
        XCTAssertEqual(network.rpcUrl, networkInfo.authenticatedRpcUrl)
        XCTAssertEqual(network.blockExplorerUrl, networkInfo.blockExplorerUrl)
        XCTAssertEqual(network.nativeCurrency?.name, networkInfo.nativeCurrency.name)
        XCTAssertEqual(network.nativeCurrency?.symbol, networkInfo.nativeCurrency.symbol)
        XCTAssertEqual(network.nativeCurrency?.decimals, Int32(networkInfo.nativeCurrency.decimals))
        XCTAssertEqual(network.theme?.textColor, networkInfo.theme.textColor)
        XCTAssertEqual(network.theme?.backgroundColor, networkInfo.theme.backgroundColor)
    }

    func test_createOrUpdate() {
        let mainNetworkInfo = makeMainnetInfo()
        var mainNetwork = Network.createOrUpdate(mainNetworkInfo)
        XCTAssertEqual(Network.count, 1)

        let testNetworkInfo = makeTestNetworkInfo(id: mainNetworkInfo.chainId)
        mainNetwork = Network.createOrUpdate(testNetworkInfo)

        XCTAssertEqual(mainNetwork.id, testNetworkInfo.chainId)
        XCTAssertEqual(mainNetwork.chainName, testNetworkInfo.chainName)
        XCTAssertEqual(mainNetwork.rpcUrl, testNetworkInfo.authenticatedRpcUrl)
        XCTAssertEqual(mainNetwork.blockExplorerUrl, testNetworkInfo.blockExplorerUrl)
        XCTAssertEqual(mainNetwork.nativeCurrency?.name, testNetworkInfo.nativeCurrency.name)
        XCTAssertEqual(mainNetwork.nativeCurrency?.symbol, testNetworkInfo.nativeCurrency.symbol)
        XCTAssertEqual(mainNetwork.nativeCurrency?.decimals, Int32(testNetworkInfo.nativeCurrency.decimals))
        XCTAssertEqual(mainNetwork.theme?.textColor, testNetworkInfo.theme.textColor)
        XCTAssertEqual(mainNetwork.theme?.backgroundColor, testNetworkInfo.theme.backgroundColor)
    }

    func test_create() {
        let networkInfo = makeMainnetInfo()
        let network = try? Network.create(networkInfo)
        XCTAssertNotNil(network)
    }

    func test_updateIfExist() {
        var testInfo = makeMainnetInfo()
        Network.updateIfExist(testInfo)
        XCTAssertEqual(Network.count, 0)

        testInfo = makeTestNetworkInfo(id: testInfo.chainId)
        let mainNetwork = Network.mainnetChain()
        Network.updateIfExist(testInfo)

        XCTAssertEqual(mainNetwork.id, testInfo.chainId)
        XCTAssertEqual(mainNetwork.chainName, testInfo.chainName)
        XCTAssertEqual(mainNetwork.rpcUrl, testInfo.authenticatedRpcUrl)
        XCTAssertEqual(mainNetwork.blockExplorerUrl, testInfo.blockExplorerUrl)
        XCTAssertEqual(mainNetwork.nativeCurrency?.name, testInfo.nativeCurrency.name)
        XCTAssertEqual(mainNetwork.nativeCurrency?.symbol, testInfo.nativeCurrency.symbol)
        XCTAssertEqual(mainNetwork.nativeCurrency?.decimals, Int32(testInfo.nativeCurrency.decimals))
        XCTAssertEqual(mainNetwork.theme?.textColor, testInfo.theme.textColor)
        XCTAssertEqual(mainNetwork.theme?.backgroundColor, testInfo.theme.backgroundColor)
    }

    func test_removingNetworkDeletesSafe() throws {
        let mainnet = Network.mainnetChain()
        Safe.create(address: "0x0000000000000000000000000000000000000000", name: "0", network: mainnet, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000001", name: "1", network: mainnet)
        XCTAssertEqual(Safe.all.count, 2)
        Network.remove(network: mainnet)
        XCTAssertEqual(Safe.all.count, 0)
    }

    func test_removeAll() {
        Network.removeAll()
        _ = try? makeNetwork(id: 1)
        _ = try? makeNetwork(id: 2)
        _ = try? makeNetwork(id: 3)

        Network.removeAll()
        XCTAssertEqual(Network.all.count, 0)
    }

    func test_mainnetChain() {
        XCTAssertNil(Network.by(Network.ChainID.ethereumMainnet))
        _ = Network.mainnetChain()
        XCTAssertNotNil(Network.by(Network.ChainID.ethereumMainnet))
    }

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

    func makeNetworkInfo(id: Int,
                         chainName: String,
                         rpcUrl: URL,
                         blockExplorerUrl: URL,
                         currencyName: String,
                         currencySymbl: String,
                         currencyDecimals: Int,
                         themeTextColor: String,
                         themeBackgroundColor: String) -> SCGModels.Network {
        SCGModels.Network(chainId: id, chainName: chainName,
                          rpcUrl: rpcUrl,
                          blockExplorerUrl: blockExplorerUrl,
                          nativeCurrency: SCGModels.Currency(name: currencyName,
                                                             symbol: currencySymbl,
                                                             decimals: currencyDecimals),
                          theme: SCGModels.Theme(textColor: themeTextColor,
                                                 backgroundColor: themeBackgroundColor))
    }

    func makeMainnetInfo() -> SCGModels.Network {
        makeNetworkInfo(id: 1,
                        chainName: "Mainnet",
                        rpcUrl: URL(string: "https://mainnet.infura.io/v3/")!,
                        blockExplorerUrl: URL(string: "https://etherscan.io/")!,
                        currencyName: "Ether",
                        currencySymbl: "ETH",
                        currencyDecimals: 18,
                        themeTextColor: "#001428",
                        themeBackgroundColor: "#E8E7E6")

    }

    func makeTestNetworkInfo(id: Int) -> SCGModels.Network {
        makeNetworkInfo(id: id,
                        chainName: "Test",
                        rpcUrl: URL(string: "https://rpc.com/")!,
                        blockExplorerUrl: URL(string: "https://block.com/")!,
                        currencyName: "Currency",
                        currencySymbl: "CRY",
                        currencyDecimals: 18,
                        themeTextColor: "#ffffff",
                        themeBackgroundColor: "#000000")
    }
}
