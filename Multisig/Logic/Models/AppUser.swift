//
//  AppUser.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 2/17/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension AppUser {

    static func all() throws -> [AppUser] {
        do {
            let context = App.shared.coreDataStack.viewContext
            let results = try context.fetch(AppUser.fetchRequest().all())
            return results
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    static func user(id: UUID) throws -> AppUser? {
        do {
            let context = App.shared.coreDataStack.viewContext
            let results = try context.fetch(AppUser.fetchRequest().by(id: id))
            return results.first
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    static func newUser() -> AppUser {
        AppUser(context: App.shared.coreDataStack.viewContext)
    }

    var encryptedPassword: String {
        get {
            do {
                if let data = try App.shared.keychainService.data(forKey: keychainKey),
                   let string = String(data: data, encoding: .utf8) {
                    return string
                }
            } catch {
                LogService.shared.error("Failed to get encrypted password", error: error)
            }
            return ""
        }
        set {
            do {
                if let data = newValue.data(using: .utf8) {
                    try removeEncryptedPassword()
                    try App.shared.keychainService.save(data: data, forKey: keychainKey)
                }
            } catch {
                LogService.shared.error("Failed to save encrypted password", error: error)
            }
        }
    }

    private var keychainKey: String {
        App.configuration.app.bundleIdentifier + id!.uuidString
    }

    func removeEncryptedPassword() throws {
        try App.shared.keychainService.removeData(forKey: keychainKey)
    }

    func save() {
        App.shared.coreDataStack.saveContext()
    }

    func delete() {
        try? removeEncryptedPassword()
        App.shared.coreDataStack.viewContext.delete(self)
        save()
    }
}

extension NSFetchRequest where ResultType == AppUser {
    func all() -> Self {
        sortDescriptors = []
        return self
    }

    func by(id: UUID) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "id == %@", id.uuidString)
        fetchLimit = 1
        return self
    }
}
