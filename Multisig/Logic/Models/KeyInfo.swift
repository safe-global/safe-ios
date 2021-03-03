//
//  KeyInfo.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 3/3/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData
import Web3

extension KeyInfo {
    /// Blockchain address that this key controls
    var address: Address? {
        get { addressString.flatMap(Address.init) }
        set { addressString = newValue?.checksummed }
    }

    /// Returns number of existing key infos
    static var count: Int {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fr = KeyInfo.fetchRequest().all()
            let itemCount = try context.count(for: fr)
            return itemCount
        } catch {
            LogService.shared.error("Failed to fetch safe count: \(error)")
            return 0
        }
    }

    /// Return the list of KeyInfo sorted alphabetically by name
    static func all() throws -> [KeyInfo] {
        let context = App.shared.coreDataStack.viewContext
        let fr = KeyInfo.fetchRequest().all()
        let items = try context.fetch(fr)
        return items
    }

    /// This will return a list of KeyInfo for the addresses that it finds in the app.
    /// - Parameter addresses: all the infos for the same address
    /// - Returns: list of key information
    static func keys(addresses: [Address]) throws -> [KeyInfo] {
        let context = App.shared.coreDataStack.viewContext
        return try addresses.compactMap { address in
            let fr = KeyInfo.fetchRequest().by(address: address)
            let item = try context.fetch(fr)
            return item.first
        }
    }

    /// Returns private keys found by the addresses. The multiple private keys option is needed when we want to sign the "push notification" payload with all of the keys available in the app.

    /// - Parameter addresses: which addresses you want to get keys?
    /// - Throws: in case of underlying errors
    /// - Returns: private keys for the addresses that were found.
    static func privateKeys(addresses: [Address]) throws -> [PrivateKey] {
        try addresses.compactMap { address in
            try PrivateKey.key(address: address)
        }
    }

    /// Will add a new key to the Keychain/Secure storage and save the key info in the persistence store.
    /// - Parameters:
    ///   - address: address of the imported key
    ///   - name: name of the imported key
    ///   - privateKey: private key to save
    static func `import`(address: Address, name: String, privateKey: PrivateKey) throws -> KeyInfo {
        let context = App.shared.coreDataStack.viewContext

        // see if already exists - then update existing, otherwise
        // create a new one
        let fr = KeyInfo.fetchRequest().by(address: address)
        let item: KeyInfo

        if let existing = try context.fetch(fr).first {
            item = existing
        } else {
            item = KeyInfo(context: context)
        }

        item.address = address
        item.name = name
        item.keyID = privateKey.id

        item.save()
        try privateKey.save()

        return item
    }

    /// Renames the key with a different name
    /// - Parameter newName: new name for the key. Not empty.
    func rename(newName: String) {
        assert(!newName.isEmpty, "name must not be empty")
        name = newName
        save()
    }

    /// Delete all of the keys stored
    static func deleteAll() throws {
        try all().forEach { try $0.delete() }
    }

    /// Deletes keys with matching addresses
    /// - Parameter addresses: addresses of keys to delete
    static func delete(addresses: [Address]) throws {
        try keys(addresses: addresses).forEach { try $0.delete() }
    }

    /// Saves the key to the persistent store
    func save() {
        App.shared.coreDataStack.saveContext()
    }

    /// Will delete the key info and the stored private key
    /// - Throws: in case of underlying error
    func delete() throws {
        if let keyID = keyID {
            try PrivateKey.remove(id: keyID)
        }
        App.shared.coreDataStack.viewContext.delete(self)
        save()
    }
}

extension NSFetchRequest where ResultType == KeyInfo {

    /// all, sorted by name, ascending
    func all() -> Self {
        sortDescriptors = [
            NSSortDescriptor(keyPath: \KeyInfo.name, ascending: true)
        ]
        return self
    }

    /// return keys with matching address
    func by(address: Address) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "address CONTAINS[c] %@", address.checksummed)
        fetchLimit = 1
        return self
    }

}
