//
//  WCAppRegistryRepositoryTests.swift
//  MultisigIntegrationTests
//
//  Created by Vitaly on 10.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//


import Foundation
@testable import Multisig
import XCTest
import WalletConnectSwift

class WCAppRegistryRepositoryTests: CoreDataTestCase {

    enum TestError: Error {
        case fileNotFound
    }

    func getData(fromJSON fileName: String) throws -> Data {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            XCTFail("Missing File: \(fileName).json")
            throw TestError.fileNotFound
        }
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            throw error
        }
    }

    func testJsonParsing() throws {
        let data = try getData(fromJSON: "wc_registry_wallets")
        let entries = try JSONDecoder().decode(JsonAppRegistry.self, from: data).entries
        XCTAssertEqual(entries.count, 149)

        let entry = entries["1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369"]!

        XCTAssertEqual(entry.name, "Rainbow")
        XCTAssertEqual(entry.versions, ["1"])
        XCTAssertEqual(entry.chains, ["eip155:1"])
    }

    func testSavesEntries() throws {
        let repository = WCAppRegistryRepository()
        let data = try getData(fromJSON: "wc_registry_wallets")
        let entries = try JSONDecoder().decode(JsonAppRegistry.self, from: data).entries.values.compactMap { entry in
            repository.entry(from: entry, role: .wallet, rank: 0)
        }

        XCTAssertEqual(entries.count, 149)

        repository.updateEntries(entries)

        let persistedEntries = repository.entries()
        XCTAssertEqual(persistedEntries.count, 132)

        let entry = repository.entries(searchTerm: "Rainbow").first!

        XCTAssertEqual(entry.name, "Rainbow")
        XCTAssertEqual(entry.versions, ["1"])
        XCTAssertEqual(entry.chains, ["1"])
    }
}
