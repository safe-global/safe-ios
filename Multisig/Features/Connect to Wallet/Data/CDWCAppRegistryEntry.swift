//
// Created by Vitaly on 09.03.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

/// CoreData object to persist information about wc registry items
extension CDWCAppRegistryEntry {

    /// Find wc registry entry by the id
    ///
    /// - Parameter id: entry id
    /// - Returns: wc registry entry or nil if not found or encountered error
    static func entry(by id: String) -> CDWCAppRegistryEntry? {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fetchRequest = CDWCAppRegistryEntry.fetchRequest().by(id: id)
            let results = try context.fetch(fetchRequest)
            let result = results.first
            return result
        } catch {
            LogService.shared.error("Failed to fetch wc app registry entry: \(error)")
            return nil
        }
    }

    static func entries(name: String?, role: Int16) throws -> [CDWCAppRegistryEntry] {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fr = CDWCAppRegistryEntry.fetchRequest().by(name: name, role: role)
            let entries = try context.fetch(fr)
            return entries
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    // get all wc registry entries
    static func getAll() throws -> [CDWCAppRegistryEntry] {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fr = CDWCAppRegistryEntry.fetchRequest().all()
            let entries = try context.fetch(fr)
            return entries
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    /// Creates new entry without saving it in the database
    static func create() -> CDWCAppRegistryEntry {
        let context = App.shared.coreDataStack.viewContext
        let result = CDWCAppRegistryEntry(context: context)
        return result
    }

    /// Deletes wc registry entry if it exists. Idempotent.
    ///
    /// - Parameter id: entry id
    static func delete(by id: String) {
        let context = App.shared.coreDataStack.viewContext
        if let entry = entry(by: id) {
            context.delete(entry)
        }
        App.shared.coreDataStack.saveContext()
    }
}

extension NSFetchRequest where ResultType == CDWCAppRegistryEntry {

    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(key: "rank", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
        return self
    }

    func by(id: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "id == %@", id)
        fetchLimit = 1
        return self
    }

    func by(name: String?, role: Int16) -> Self {
        sortDescriptors = [NSSortDescriptor(key: "rank", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
        if let name = name {
            predicate = NSPredicate(format: "homepage contains[c] %@ OR name contains[c] %@ AND role == %i",
                                    name,
                                    name,
                                    role)
        } else {
            predicate = NSPredicate(format: "role == %i", role)
        }
        return self
    }
}
