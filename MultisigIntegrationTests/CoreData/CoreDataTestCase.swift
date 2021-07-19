//
//  CoreDataTestCase.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 21.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import Multisig

class CoreDataTestCase: XCTestCase {
    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        App.shared.coreDataStack = TestCoreDataStack()
        context = App.shared.coreDataStack.viewContext
    }

    @discardableResult
    func createSafe(name: String, address: String, network: Network = Network.mainnetChain()) -> Safe {
        let safe = Safe(context: context)
        safe.name = name
        safe.address = address
        safe.network = network
        try! context.save()
        return safe
    }

    func makeNetwork(id: String) throws -> Network {
        try Network.create(
            chainId: id,
            chainName: "Test",
            rpcUrl: URL(string: "https://rpc.com/")!,
            blockExplorerUrl: URL(string: "https://block.com/")!,
            ensRegistryAddress: "0x0000000000000000000000000000000000000001",
            recommendedMasterCopyVersion: "0x0000000000000000000000000000000000000001",
            currencyName: "Currency",
            currencySymbl: "CRY",
            currencyDecimals: 18,
            currencyLogo: URL(string: "https://example.com/crylogo.png")!,
            themeTextColor: "#ffffff",
            themeBackgroundColor: "#000000")
    }
}
