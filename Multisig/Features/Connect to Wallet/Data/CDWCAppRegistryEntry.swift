//
// Created by Vitaly on 09.03.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

/// CoreData object to persist information about wc registry items
extension CDWCAppRegistryEntry {

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
}

extension NSFetchRequest where ResultType == CDWCAppRegistryEntry {

    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return self
    }
}
