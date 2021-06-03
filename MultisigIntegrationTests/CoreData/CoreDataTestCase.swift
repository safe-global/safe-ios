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
}
