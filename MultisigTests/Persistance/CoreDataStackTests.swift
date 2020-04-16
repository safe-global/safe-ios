//
//  SafeMOTests.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 15.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import Multisig

class CoreDataStackTests: XCTestCase {
    let coreDataStack = TestCoreDataStack()
    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        context = coreDataStack.persistentContainer.viewContext
    }

    func testCRUD() throws {
        // check that initially all Safes are empty
        let initialSafesResult = try context.fetch(Safe.allSafes())
        XCTAssertTrue(initialSafesResult.isEmpty)

        // Insert object with NSEntityDescription
        let newSafe1 = NSEntityDescription.insertNewObject(forEntityName: "Safe", into: context) as! Safe
        newSafe1.name = "Safe 1"
        try context.save()
        let oneSafeResult = try context.fetch(Safe.allSafes())
        XCTAssertEqual(oneSafeResult.count, 1)
        XCTAssertEqual(oneSafeResult[0].name, "Safe 1")

        // Update object
        newSafe1.contractVersion = "1.1.1"
        try context.save()
        let updatedSafesResult = try context.fetch(Safe.allSafes())
        XCTAssertEqual(updatedSafesResult.count, 1)
        XCTAssertEqual(updatedSafesResult[0].contractVersion, "1.1.1")

        // Insert object using auto-generated class
        let newSafe0 = Safe(context: context)
        newSafe0.name = "Safe 0"
        // Without saving the context, fetch request should be updated
        let twoSafesResultBeforeSave = try context.fetch(Safe.allSafes())
        XCTAssertEqual(twoSafesResultBeforeSave.count, 2)
        // result safes should be sorted by name
        XCTAssertEqual(twoSafesResultBeforeSave[0].name, "Safe 0")
        XCTAssertEqual(twoSafesResultBeforeSave[1].name, "Safe 1")

        // reset context; not saved object is discarded
        context.reset()
        let oneSafeResultAfterReseting = try context.fetch(Safe.allSafes())
        XCTAssertEqual(oneSafeResultAfterReseting.count, 1)
        XCTAssertEqual(oneSafeResultAfterReseting[0].name, "Safe 1")

        // Delete entry
        // NOTE: we can not use here 'newSafe1' variable as the context was reset
        context.delete(oneSafeResultAfterReseting[0])
        try context.save()
        // deleting did not affect previous fetch results
        XCTAssertEqual(oneSafeResultAfterReseting.count, 1)
        let oneSafeResultAfterDeleting = try context.fetch(Safe.allSafes())
        XCTAssertEqual(oneSafeResultAfterDeleting.count, 0)
    }

}
