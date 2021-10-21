//
//  AddressBookEntity.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 20/10/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

// "address:chainId" -> name
fileprivate var cachedNames = [String: String]()

extension AddressBookEntity {
    var displayAddress: String { address! }
    var addressValue: Address { Address(address!)! }

    static var count: Int {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.count(for: AddressBookEntity.fetchRequest().all())) ?? 0
    }

    static var all: [AddressBookEntity] {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.fetch(AddressBookEntity.fetchRequest().all())) ?? []
    }

    static func by(address: String, chainId: String) -> AddressBookEntity? {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = AddressBookEntity.fetchRequest().by(address: address, chainId: chainId)
        return try? context.fetch(fr).first
    }

    static func by(chainId: String) -> [AddressBookEntity]? {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = AddressBookEntity.fetchRequest().by(chainId: chainId)
        return try? context.fetch(fr)
    }

    static func updateCachedNames() {
        guard let entities = try? AddressBookEntity.getAll() else { return }

        cachedNames = entities.reduce(into: [String: String]()) { names, entity in
            let chainId = entity.chain != nil ? entity.chain!.id! : "1"
            let key = "\(entity.displayAddress):\(chainId)"
            names[key] = entity.name!
        }
    }

    static func cachedName(by address: AddressString, chainId: String) -> String? {
        let key = "\(address.description):\(chainId)"
        return cachedNames[key]
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        additionDate = Date()
    }

    static func getAll() throws -> [AddressBookEntity] {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fr = AddressBookEntity.fetchRequest().all()
            let entities = try context.fetch(fr)
            return entities
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    static func exists(_ address: String, chainId: String) -> Bool {
        by(address: address, chainId: chainId) != nil
    }

    static func update(_ address: String, chainId: String, name: String) {
        dispatchPrecondition(condition: .onQueue(.main))

        guard let entity = by(address: address, chainId: chainId) else { return }
        entity.name = name
        App.shared.coreDataStack.saveContext()
        AddressBookEntity.updateCachedNames()

        NotificationCenter.default.post(name: .addressbookChanged, object: nil)
    }

    @discardableResult
    static func create(address: String, name: String, chain: Chain) -> AddressBookEntity {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        let entity = AddressBookEntity(context: context)
        entity.address = address
        entity.name = name
        entity.chain = chain

        App.shared.coreDataStack.saveContext()

        updateCachedNames()

        return entity
    }

    func update(name: String) {
        dispatchPrecondition(condition: .onQueue(.main))

        self.name = name

        App.shared.coreDataStack.saveContext()


        AddressBookEntity.updateCachedNames()

        NotificationCenter.default.post(name: .addressbookChanged, object: nil)
    }

    static func remove(entity: AddressBookEntity) {
        let context = App.shared.coreDataStack.viewContext
        context.delete(entity)
        App.shared.coreDataStack.saveContext()
        updateCachedNames()
        NotificationCenter.default.post(name: .addressbookChanged, object: nil)
    }

    static func removeAll() throws {
        for entity in all {
            remove(entity: entity)
        }

        NotificationCenter.default.post(name: .addressbookChanged, object: nil)
    }
}

extension AddressBookEntity {
    func update(address: Address, name: String) {
        self.name = name
    }
}

extension NSFetchRequest where ResultType == AddressBookEntity {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \AddressBookEntity.additionDate, ascending: true)]
        return self
    }

    func by(address: String, chainId: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "address == %@ AND chain.id == %@", address, chainId)
        fetchLimit = 1
        return self
    }

    func by(chainId: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "chain.id == %@", chainId)
        return self
    }
}
