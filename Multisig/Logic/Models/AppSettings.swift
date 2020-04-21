//
//  AppSettings.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 20.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension AppSettings {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.createdAt = Date()
    }

    // MARK: - Fetch Requests

    static func settings() -> NSFetchRequest<AppSettings> {
        let request: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AppSettings.createdAt, ascending: true)]
        request.fetchLimit = 1
        return request
    }

    // MARK: - Manipulating entities

    static func getOrCreate(
        context: NSManagedObjectContext = CoreDataStack.shared.persistentContainer.viewContext) -> AppSettings {
        guard let settings = try? context.fetch(settings()), !settings.isEmpty else {
            return AppSettings(context: context)
        }
        return settings[0]
    }
}
