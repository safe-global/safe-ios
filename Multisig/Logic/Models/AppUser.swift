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

    static func newUser(id: UUID) -> AppUser {
        let user = AppUser(context: App.shared.coreDataStack.viewContext)
        user.id = id
        return user
    }

    func encryptedPassword() throws -> String? {
        // keychain might be not accessible. In this case we don't know if there's encrypted password or not
        // we must gracefully finish whatever operation is going on.
        if let data = try App.shared.keychainService.data(forKey: keychainKey),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return nil
    }

    func setEncryptedPassword(_ newValue: String) throws {
        if let data = newValue.data(using: .utf8) {
            // keychain might fail
            try removeEncryptedPassword()
            // keychain might fail
            try App.shared.keychainService.save(data: data, forKey: keychainKey)
        }
    }

    private var keychainKey: String {
        App.configuration.app.bundleIdentifier + id!.uuidString
    }

    // keychain might fail
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
