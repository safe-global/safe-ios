//
//  TestCoreDataStack.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 15.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import CoreData
@testable import Multisig

#if DEBUG

class TestCoreDataStack {

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Multisig")
        let description = container.persistentStoreDescriptions.first!
        description.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    static let shared = TestCoreDataStack().setUp()

    static var context: NSManagedObjectContext { Self.shared.persistentContainer.viewContext }

    func setUp() -> Self {
        let context = persistentContainer.viewContext
        for i in 1...4 {
            let safe = Safe(context: context)
            safe.name = "Safe \(i)"
            safe.address = "0x\(i)"
        }
        let safe = Safe(context: context)
        safe.name = "Safe 5"
        safe.address = "0x55555555555"
        safe.select()
        return self
    }
}

#endif
