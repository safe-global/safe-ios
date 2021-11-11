//
//  AddressBookEntryTests.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 21.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class AddressBookTests: CoreDataTestCase {
    func test_removeAddressBookEntry() throws {
        let network1 = try makeChain(id: "1")
        let network2 = try makeChain(id: "2")

        AddressBookEntry.create(address: "0x0000000000000000000000000000000000000000", name: "0", chain: network1)
        AddressBookEntry.create(address: "0x0000000000000000000000000000000000000001", name: "1", chain: network1)
        AddressBookEntry.create(address: "0x0000000000000000000000000000000000000002", name: "2", chain: network2)

        var entriesResult = try context.fetch(AddressBookEntry.fetchRequest().all())
        var networksResult = try context.fetch(Chain.fetchRequest().all())
        XCTAssertEqual(entriesResult.count, 3)
        XCTAssertEqual(networksResult.count, 2)

        var entry = entriesResult.first!
        AddressBookEntry.remove(entry: entry)
        entriesResult = try context.fetch(AddressBookEntry.fetchRequest().all())
        networksResult = try context.fetch(Chain.fetchRequest().all())
        XCTAssertEqual(entriesResult.count, 2)
        XCTAssertEqual(networksResult.count, 2)

        entry = entriesResult.first!
        AddressBookEntry.remove(entry: entry)
        entriesResult = try context.fetch(AddressBookEntry.fetchRequest().all())
        networksResult = try context.fetch(Chain.fetchRequest().all())
        XCTAssertEqual(entriesResult.count, 1)
        XCTAssertEqual(networksResult.count, 2)

        entry = entriesResult.first!
        AddressBookEntry.remove(entry: entry)
        entriesResult = try context.fetch(AddressBookEntry.fetchRequest().all())
        networksResult = try context.fetch(Chain.fetchRequest().all())
        XCTAssertEqual(entriesResult.count, 0)
        XCTAssertEqual(networksResult.count, 2)
    }

    func test_allEntries() throws {
        let entry0 = createEntry(name: "1", address: "0x1")
        let entry1 = createEntry(name: "0", address: "0x0")
        let allEntries = try AddressBookEntry.getAll()
        XCTAssertEqual(allEntries.count, 2)
        // should be sorted by name
        XCTAssertEqual(allEntries[0], entry1)
        XCTAssertEqual(allEntries[1], entry0)
    }

    func test_entryBy() throws {
        let entry = createEntry(name: "0", address: "0x0")
        createEntry(name: "1", address: "0x1")
        let result = AddressBookEntry.by(address: "0x0", chainId: Chain.ChainID.ethereumMainnet)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, entry)
    }

    func test_update() {
        let entry = createEntry(name: "0", address: Address.zero.checksummed)
        entry.update(name: "1")
        let result = AddressBookEntry.by(address: Address.zero.checksummed, chainId: Chain.ChainID.ethereumMainnet)
        XCTAssertEqual(result!.name, "1")
    }
}
