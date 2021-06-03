//
//  CoreDataController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 15.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData
import Combine

class CoreDataStack: CoreDataProtocol {
    private var subscribers = Set<AnyCancellable>()

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Multisig")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                // merge changes from background contexts into the view context
                NotificationCenter.default
                .publisher(for: Notification.Name.NSManagedObjectContextDidSave)
                .receive(on: RunLoop.main)
                .sink { [unowned container] notification in
                        let savedMOC = notification.object as! NSManagedObjectContext
                        guard savedMOC != container.viewContext,
                            savedMOC.persistentStoreCoordinator == container.persistentStoreCoordinator else { return }
                        container.viewContext.mergeChanges(fromContextDidSave: notification)
                }
                .store(in: &self.subscribers)
            }
        }
        return container
    }()

    func saveContext () {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
