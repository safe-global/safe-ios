//
//  TestCoreDataStack.swift
//  MultisigTests
//
//  Created by Andrey Scherbovich on 15.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import CoreData
@testable import Multisig

//#if DEBUG
// This class is part of Multisig target so we could use it in previews.

class TestCoreDataStack: CoreDataProtocol {
    // Using the in-memory container unit testing requires loading the xcdatamodel to be loaded from the main bundle
    var managedObjectModel: NSManagedObjectModel = {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        return managedObjectModel
    }()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MultisigTests", managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved CoreData error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    func saveContext() {
        try! viewContext.save()
    }

    func rollback() {
        viewContext.rollback()
    }
}

//#endif
