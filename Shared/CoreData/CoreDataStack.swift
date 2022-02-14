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

    @ConfigurationKey("APP_GROUP_ID")
    static var appGroupId: String

    // Loads core data store and migrates from previous versions if needed.
    lazy var persistentContainer: NSPersistentContainer = {
        // By default, container configured with database located in app sandbox.
        let container = NSPersistentContainer(name: "Multisig")

        // Get the default location
        let defaultStoreUrl = container.persistentStoreDescriptions.first?.url
        let defaultStoreExists = defaultStoreUrl != nil && FileManager.default.fileExists(atPath: defaultStoreUrl!.path)

        // Get app group container location
        guard let appGroupContainerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupId) else {
            fatalError("Expected to have App Group set up with id: \(Self.appGroupId)")
        }

        // Check if already migrated default store to the shared app group location
        let sharedStoreUrl = appGroupContainerUrl.appendingPathComponent("Multisig").appendingPathExtension("sqlite")
        var sharedStoreExists = FileManager.default.fileExists(atPath: sharedStoreUrl.path)

        let didNotMigrate = defaultStoreExists && !sharedStoreExists

        if !didNotMigrate {
            container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: sharedStoreUrl)]
        }

        container.loadPersistentStores { [unowned container] storeDescription, error in
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
            }


            // migrate store if needed
            if didNotMigrate,
               let defaultStore = container.persistentStoreCoordinator.persistentStore(for: defaultStoreUrl!) {
                do {
                    try container.persistentStoreCoordinator.migratePersistentStore(
                        defaultStore,
                        to: sharedStoreUrl,
                        options: nil,
                        withType: defaultStore.type)

                    sharedStoreExists = true
                } catch {
                    print("Failed to migrate persistent store to new location: \(error)")
                    sharedStoreExists = false
                }
            }

            if defaultStoreExists && sharedStoreExists {
                try? FileManager.default.removeItem(at: defaultStoreUrl!)
            }

            // merge changes from background contexts into the view context
            NotificationCenter.default
                .publisher(for: Notification.Name.NSManagedObjectContextDidSave)
                .receive(on: RunLoop.main)
                .sink { [weak container] notification in
                    let savedMOC = notification.object as! NSManagedObjectContext
                    guard let container = container,
                          savedMOC != container.viewContext,
                          savedMOC.persistentStoreCoordinator == container.persistentStoreCoordinator else { return }
                    container.viewContext.mergeChanges(fromContextDidSave: notification)
                }
                .store(in: &self.subscribers)

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

    func rollback() {
        if viewContext.hasChanges {
            viewContext.rollback()
        }
    }
}
