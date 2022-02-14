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
        XCTAssertEqual(Chain.count, 0)
    }

    func test_count_whenMultipleExists_thenReturnsCorrectCount() throws {
        _ = try makeChain(id: "1")
        _ = try makeChain(id: "2")
        _ = try makeChain(id: "3")

        XCTAssertEqual(Chain.count, 3)
    }

    func test_all() throws {
        XCTAssertEqual(Chain.count, 0)
        let network0 = try makeChain(id: "1")
        let network1 = try makeChain(id: "2")
        let network2 = try makeChain(id: "3")

        let networks = Chain.all
        XCTAssertEqual(networks.count, 3)
        XCTAssertEqual(network0, networks[0])
        XCTAssertEqual(network1, networks[1])
        XCTAssertEqual(network2, networks[2])
    }

    func test_exists() {
        XCTAssertFalse(try Chain.exists("1"))
        _ = try? makeChain(id: "1")

        XCTAssertFalse(try Chain.exists("2"))
        XCTAssertTrue(try Chain.exists("1"))
    }

    func test_by() {
        var chain = Chain.by("1")
        XCTAssertNil(chain)
        _ = try? makeChain(id: "1")

        chain = Chain.by("2")
        XCTAssertNil(chain)

        chain = Chain.by("1")
        XCTAssertNotNil(chain)
    }

    // MARK: create(params)

    func test_create_whenCreatedThenHasCorrectParameters() throws {
        let chain = try makeChain(id: "1")

        // assert
        XCTAssertEqual(chain.id, "1")
        XCTAssertEqual(chain.name, "Test")
        XCTAssertEqual(chain.rpcUrl, URL(string: "https://rpc.com/")!)
        XCTAssertEqual(chain.blockExplorerUrlAddress, "https://block.com/address/{{address}}")
        XCTAssertEqual(chain.blockExplorerUrlTxHash, "https://block.com/tx/{{txHash}}")
        XCTAssertEqual(chain.ensRegistryAddress, "0x0000000000000000000000000000000000000001")
        XCTAssertEqual(chain.shortName, "eth")
        XCTAssertEqual(chain.nativeCurrency?.name, "Currency")
        XCTAssertEqual(chain.nativeCurrency?.symbol, "CRY")
        XCTAssertEqual(chain.nativeCurrency?.decimals, 18)
        XCTAssertEqual(chain.theme?.textColor, "#ffffff")
        XCTAssertEqual(chain.theme?.backgroundColor, "#000000")
    }

    func test_create_whenCreatedWithDuplicateChainId_thenThrows() throws {
        _ = try makeChain(id: "1")

        XCTAssertThrowsError(try makeChain(id: "1"))
    }

    func test_update() throws {
        let chain = Chain.mainnetChain()

        // updating with different chain id
        var chainInfo = makeTestNetworkInfo(id: UInt256(chain.id!)! + 1)
        XCTAssertThrowsError(
            try chain.update(from: chainInfo)
        )

        chainInfo = makeTestNetworkInfo(id: UInt256(chain.id!)!)

        // updating with same chain id
        XCTAssertNoThrow(
            try chain.update(from: chainInfo)
        )

        XCTAssertEqual(chain.id, chainInfo.id)
        XCTAssertEqual(chain.name, chainInfo.chainName)
        XCTAssertEqual(chain.rpcUrl, chainInfo.rpcUri.value)
        XCTAssertEqual(chain.rpcUrlAuthentication, chainInfo.rpcUri.authentication.rawValue)
        XCTAssertEqual(chain.blockExplorerUrlAddress, chainInfo.blockExplorerUriTemplate.address)
        XCTAssertEqual(chain.blockExplorerUrlTxHash, chainInfo.blockExplorerUriTemplate.txHash)
        XCTAssertEqual(chain.ensRegistryAddress, chainInfo.ensRegistryAddress?.description)
        XCTAssertEqual(chain.shortName, chainInfo.shortName)

        XCTAssertEqual(chain.nativeCurrency?.name, chainInfo.nativeCurrency.name)
        XCTAssertEqual(chain.nativeCurrency?.symbol, chainInfo.nativeCurrency.symbol)
        XCTAssertEqual(chain.nativeCurrency?.decimals, Int32(chainInfo.nativeCurrency.decimals))
        XCTAssertEqual(chain.nativeCurrency?.logoUrl, chainInfo.nativeCurrency.logoUri)

        XCTAssertEqual(chain.theme?.textColor, chainInfo.theme.textColor)
        XCTAssertEqual(chain.theme?.backgroundColor, chainInfo.theme.backgroundColor)
    }

    func test_createOrUpdate() {
        let mainNetworkInfo = makeMainnetInfo()
        var mainNetwork = Chain.createOrUpdate(mainNetworkInfo)
        XCTAssertEqual(Chain.count, 1)

        let testNetworkInfo = makeTestNetworkInfo(id: mainNetworkInfo.chainId.value)
        mainNetwork = Chain.createOrUpdate(testNetworkInfo)

        XCTAssertEqual(mainNetwork.id, testNetworkInfo.id)
        XCTAssertEqual(mainNetwork.name, testNetworkInfo.chainName)
        XCTAssertEqual(mainNetwork.rpcUrl, testNetworkInfo.rpcUri.value)
        XCTAssertEqual(mainNetwork.rpcUrlAuthentication, testNetworkInfo.rpcUri.authentication.rawValue)

        XCTAssertEqual(mainNetwork.blockExplorerUrlAddress, testNetworkInfo.blockExplorerUriTemplate.address)
        XCTAssertEqual(mainNetwork.blockExplorerUrlTxHash, testNetworkInfo.blockExplorerUriTemplate.txHash)
        XCTAssertEqual(mainNetwork.ensRegistryAddress, testNetworkInfo.ensRegistryAddress?.description)
        XCTAssertEqual(mainNetwork.shortName, testNetworkInfo.shortName)

        XCTAssertEqual(mainNetwork.nativeCurrency?.name, testNetworkInfo.nativeCurrency.name)
        XCTAssertEqual(mainNetwork.nativeCurrency?.symbol, testNetworkInfo.nativeCurrency.symbol)
        XCTAssertEqual(mainNetwork.nativeCurrency?.decimals, Int32(testNetworkInfo.nativeCurrency.decimals))
        XCTAssertEqual(mainNetwork.nativeCurrency?.logoUrl, testNetworkInfo.nativeCurrency.logoUri)

        XCTAssertEqual(mainNetwork.theme?.textColor, testNetworkInfo.theme.textColor)
        XCTAssertEqual(mainNetwork.theme?.backgroundColor, testNetworkInfo.theme.backgroundColor)
    }

    func test_create() {
        let networkInfo = makeMainnetInfo()
        let chain = try? Chain.create(networkInfo)
        XCTAssertNotNil(chain)
    }

    func test_updateIfExist() {
        var testInfo = makeMainnetInfo()
        Chain.updateIfExist(testInfo)
        XCTAssertEqual(Chain.count, 0)

        testInfo = makeTestNetworkInfo(id: testInfo.chainId.value)
        let mainNetwork = Chain.mainnetChain()
        Chain.updateIfExist(testInfo)

        XCTAssertEqual(mainNetwork.id, testInfo.id)
        XCTAssertEqual(mainNetwork.name, testInfo.chainName)
        XCTAssertEqual(mainNetwork.rpcUrl, testInfo.rpcUri.value)
        XCTAssertEqual(mainNetwork.rpcUrlAuthentication, testInfo.rpcUri.authentication.rawValue)
        XCTAssertEqual(mainNetwork.blockExplorerUrlAddress, testInfo.blockExplorerUriTemplate.address)
        XCTAssertEqual(mainNetwork.blockExplorerUrlTxHash, testInfo.blockExplorerUriTemplate.txHash)
        XCTAssertEqual(mainNetwork.shortName, testInfo.shortName)

        XCTAssertEqual(mainNetwork.nativeCurrency?.name, testInfo.nativeCurrency.name)
        XCTAssertEqual(mainNetwork.nativeCurrency?.symbol, testInfo.nativeCurrency.symbol)
        XCTAssertEqual(mainNetwork.nativeCurrency?.decimals, Int32(testInfo.nativeCurrency.decimals))
        XCTAssertEqual(mainNetwork.nativeCurrency?.logoUrl, testInfo.nativeCurrency.logoUri)

        XCTAssertEqual(mainNetwork.theme?.textColor, testInfo.theme.textColor)
        XCTAssertEqual(mainNetwork.theme?.backgroundColor, testInfo.theme.backgroundColor)
    }

    func test_removingNetworkDeletesSafe() throws {
        let mainnet = Chain.mainnetChain()
        Safe.create(address: "0x0000000000000000000000000000000000000000", version: "1.2.0", name: "0", chain: mainnet, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000001", version: "1.2.0", name: "1", chain: mainnet)
        XCTAssertEqual(Safe.all.count, 2)
        Chain.remove(chain: mainnet)
        XCTAssertEqual(Safe.all.count, 0)
    }

    func test_removeAll() {
        Chain.removeAll()
        _ = try? makeChain(id: "1")
        _ = try? makeChain(id: "2")
        _ = try? makeChain(id: "3")

        Chain.removeAll()
        XCTAssertEqual(Chain.all.count, 0)
    }

    func test_mainnetChain() {
        XCTAssertNil(Chain.by(Chain.ChainID.ethereumMainnet))
        _ = Chain.mainnetChain()
        XCTAssertNotNil(Chain.by(Chain.ChainID.ethereumMainnet))
    }

    func test_networkSafes() throws {
        var networkSafes = Chain.chainSafes()
        XCTAssertEqual(networkSafes.count, 0)

        let network1 = try makeChain(id: "1")
        let network3 = try makeChain(id: "3")
        let network2 = try makeChain(id: "2")

        Safe.create(address: "0x0000000000000000000000000000000000000000", version: "1.2.0", name: "00", chain: network1, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000001", version: "1.2.0", name: "01", chain: network1, selected: false)

        Safe.create(address: "0x0000000000000000000000000000000000000011", version: "1.2.0", name: "11", chain: network3, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000010", version: "1.2.0", name: "10", chain: network3, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000000", version: "1.2.0", name: "100", chain: network3, selected: false)

        Safe.create(address: "0x0000000000000000000000000000000000000020", version: "1.2.0", name: "20", chain: network2, selected: false)
        Safe.create(address: "0x0000000000000000000000000000000000000021", version: "1.2.0", name: "21", chain: network2, selected: true)
        Safe.create(address: "0x0000000000000000000000000000000000000022", version: "1.2.0", name: "22", chain: network2, selected: false)

        networkSafes = Chain.chainSafes()

        XCTAssertEqual(networkSafes.count, 3)

        XCTAssertEqual(networkSafes[0].chain, network2)
        XCTAssertEqual(networkSafes[0].safes.count, 3)
        XCTAssertEqual(networkSafes[0].safes[0].name, "21")
        XCTAssertEqual(networkSafes[0].safes[1].name, "22")
        XCTAssertEqual(networkSafes[0].safes[2].name, "20")

        XCTAssertEqual(networkSafes[1].chain, network1)
        XCTAssertEqual(networkSafes[1].safes.count, 2)
        XCTAssertEqual(networkSafes[1].safes[0].name, "01")
        XCTAssertEqual(networkSafes[1].safes[1].name, "00")

        XCTAssertEqual(networkSafes[2].chain, network3)
        XCTAssertEqual(networkSafes[2].safes.count, 3)
        XCTAssertEqual(networkSafes[2].safes[0].name, "100")
        XCTAssertEqual(networkSafes[2].safes[1].name, "10")
        XCTAssertEqual(networkSafes[2].safes[2].name, "11")
    }

    func test_networkEntries() throws {
        var networkEntries = Chain.chainEntries()
        XCTAssertEqual(networkEntries.count, 0)

        let network1 = try makeChain(id: "1")
        let network3 = try makeChain(id: "3")
        let network2 = try makeChain(id: "2")

        AddressBookEntry.create(address: "0x0000000000000000000000000000000000000000", name: "00", chain: network1)
        AddressBookEntry.create(address: "0x0000000000000000000000000000000000000001", name: "01", chain: network1)

        AddressBookEntry.create(address: "0x0000000000000000000000000000000000000011", name: "11", chain: network3)
        AddressBookEntry.create(address: "0x0000000000000000000000000000000000000010", name: "10", chain: network3)
        AddressBookEntry.create(address: "0x0000000000000000000000000000000000000000", name: "100", chain: network3)

        AddressBookEntry.create(address: "0x0000000000000000000000000000000000000020", name: "20", chain: network2)
        AddressBookEntry.create(address: "0x0000000000000000000000000000000000000021", name: "21", chain: network2)
        AddressBookEntry.create(address: "0x0000000000000000000000000000000000000022", name: "22", chain: network2)

        networkEntries = Chain.chainEntries()

        XCTAssertEqual(networkEntries.count, 3)

        XCTAssertEqual(networkEntries[0].chain, network1)
        XCTAssertEqual(networkEntries[0].entries.count, 2)
        XCTAssertEqual(networkEntries[0].entries[0].name, "00")
        XCTAssertEqual(networkEntries[0].entries[1].name, "01")

        XCTAssertEqual(networkEntries[1].chain, network2)
        XCTAssertEqual(networkEntries[1].entries.count, 3)
        XCTAssertEqual(networkEntries[1].entries[0].name, "20")
        XCTAssertEqual(networkEntries[1].entries[1].name, "21")
        XCTAssertEqual(networkEntries[1].entries[2].name, "22")

        XCTAssertEqual(networkEntries[2].chain, network3)
        XCTAssertEqual(networkEntries[2].entries.count, 3)
        XCTAssertEqual(networkEntries[2].entries[0].name, "10")
        XCTAssertEqual(networkEntries[2].entries[1].name, "100")
        XCTAssertEqual(networkEntries[2].entries[2].name, "11")
    }

    // nativeCurrency
    func test_nativeCurrency() throws {
        // when no safes then nil returned
        XCTAssertNil(Chain.nativeCoin)

        // when no selected safe then nil returned
        let chain1 = try makeChain(id: "1")
        let safe = Safe.create(address: "0x0000000000000000000000000000000000000000", version: "1.2.0", name: "00", chain: chain1, selected: false)
        XCTAssertNil(Chain.nativeCoin)

        // when selected safe then chain's token returned
        safe.select()
        XCTAssertEqual(Chain.nativeCoin, chain1.nativeCurrency)
    }

    func makeNetworkInfo(id: UInt256,
                         chainName: String,
                         rpcUrl: URL,
                         rpcUrlAuthentication: SCGModels.RpcAuthentication.Authentication = .apiKeyPath,
                         blockExplorerUrlAddress: String,
                         blockExplorerUrlTxHash: String,
                         shortName: String,
                         currencyName: String,
                         currencySymbl: String,
                         currencyDecimals: Int,
                         currencyLogo: URL,
                         themeTextColor: String,
                         themeBackgroundColor: String) -> SCGModels.Chain {

        SCGModels.Chain(
                chainId: UInt256String(id),
                chainName: chainName,
                rpcUri: SCGModels.RpcAuthentication(authentication: rpcUrlAuthentication, value: rpcUrl),
                blockExplorerUriTemplate: SCGModels.BlockExplorerUriTemplate(address: blockExplorerUrlAddress,
                                                                             txHash: blockExplorerUrlTxHash),
                nativeCurrency: SCGModels.Currency(name: currencyName,
                                                   symbol: currencySymbl,
                                                   decimals: currencyDecimals,
                                                   logoUri: currencyLogo),
                theme: SCGModels.Theme(textColor: themeTextColor,
                                       backgroundColor: themeBackgroundColor),
                ensRegistryAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
                shortName: shortName,
                l2: false,
                features: [],
                gasPrice: [])
    }

    func makeMainnetInfo() -> SCGModels.Chain {
        makeNetworkInfo(id: 1,
                        chainName: "Mainnet",
                        rpcUrl: URL(string: "https://mainnet.infura.io/v3/")!,
                        blockExplorerUrlAddress: "https://etherscan.io/address/{{address}}",
                        blockExplorerUrlTxHash: "https://etherscan.io/tx/{{txHash}}",
                        shortName: "eth",
                        currencyName: "Ether",
                        currencySymbl: "ETH",
                        currencyDecimals: 18,
                        currencyLogo: URL(string: "https://example.com/mainnet.png")!,
                        themeTextColor: "#001428",
                        themeBackgroundColor: "#E8E7E6")

    }

    func makeTestNetworkInfo(id: UInt256) -> SCGModels.Chain {
        makeNetworkInfo(id: id,
                        chainName: "Test",
                        rpcUrl: URL(string: "https://rpc.com/")!,
                        blockExplorerUrlAddress: "https://block.com/address/{{address}}",
                        blockExplorerUrlTxHash: "https://block.com/tx/{{txHash}}",
                        shortName: "eth",
                        currencyName: "Currency",
                        currencySymbl: "CRY",
                        currencyDecimals: 18,
                        currencyLogo: URL(string: "https://example.com/cry.png")!,
                        themeTextColor: "#ffffff",
                        themeBackgroundColor: "#000000")
    }
}
