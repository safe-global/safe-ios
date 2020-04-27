//
//  SafeMO.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 15.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension Safe: Identifiable {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.createdAt = Date()
    }

    func save() {
        CoreDataStack.shared.saveContext()
    }

    static func download(at address: String) throws {
        _ = try App.shared.safeRelayService.safeInfo(at: address)
    }

    static func alreadyExists(_ address: String) throws -> Bool {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let count = try context.count(for: Safe.by(address: address))
        return count > 0
    }

    static func create(address: String, name: String, selected: Bool = true) {
        let context = CoreDataStack.shared.persistentContainer.viewContext

        let safe = Safe(context: context)
        safe.address = address
        safe.name = name

        if selected {
            let settings = AppSettings.getOrCreate(context: context)
            settings.selectedSafe = address
        }

        do {
            try context.save()
        } catch {
            print(error)
            fatalError()
        }
    }

    // MARK: - Fetch Requests

    static func allSafes() -> NSFetchRequest<Safe> {
        let request: NSFetchRequest<Safe> = Safe.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Safe.createdAt, ascending: true)]
        return request
    }

    static func by(address: String) -> NSFetchRequest<Safe> {
        let request: NSFetchRequest<Safe> = Safe.fetchRequest()
        request.predicate = NSPredicate(format: "address == %@", address)
        request.fetchLimit = 1
        return request
    }

}
