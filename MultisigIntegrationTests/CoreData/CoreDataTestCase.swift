//
//  CoreDataTestCase.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 21.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
import CoreData
import Version
@testable import Multisig

class CoreDataTestCase: XCTestCase {
    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        App.shared.coreDataStack = TestCoreDataStack()
        context = App.shared.coreDataStack.viewContext
    }

    @discardableResult
    func createSafe(name: String, address: String, chain: Chain = Chain.mainnetChain(), contractVersion: String = Version(1, 3, 0).description) -> Safe {
        let safe = Safe(context: context)
        safe.name = name
        safe.address = address
        safe.chain = chain
        safe.contractVersion = contractVersion
        try! context.save()
        return safe
    }

    @discardableResult
    func createEntry(name: String, address: String, chain: Chain = Chain.mainnetChain()) -> AddressBookEntry {
        let entry = AddressBookEntry(context: context)
        entry.name = name
        entry.address = address
        entry.chain = chain
        try! context.save()
        return entry
    }

    func makeChain(id: String) throws -> Chain {
        try Chain.create(
            chainId: id,
            chainName: "Test",
            rpcUrl: URL(string: "https://rpc.com/")!,
            rpcUrlAuthentication: SCGModels.RpcAuthentication.Authentication.apiKeyPath.rawValue,
            blockExplorerUrlAddress: "https://block.com/address/{{address}}",
            blockExplorerUrlTxHash: "https://block.com/tx/{{txHash}}",
            ensRegistryAddress: "0x0000000000000000000000000000000000000001",
            shortName: "eth",
            currencyName: "Currency",
            currencySymbl: "CRY",
            currencyDecimals: 18,
            currencyLogo: URL(string: "https://example.com/crylogo.png")!,
            themeTextColor: "#ffffff",
            themeBackgroundColor: "#000000")
    }
}
