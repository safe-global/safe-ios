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

    var isSelected: Bool { selection != nil }

    var hasAddress: Bool { address?.isEmpty == false }

    var displayAddress: String { address! }

    var browserURL: URL { Self.browserURL(address: displayAddress) }

    var displayName: String { name.flatMap { $0.isEmpty ? nil : $0 } ?? "Untitled Safe" }

    var displayENSName: String { "" }

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        additionDate = Date()
    }

    func select() {
        let selection = Selection.current()
        selection.safe = self
        CoreDataStack.shared.saveContext()
    }

    static func browserURL(address: String) -> URL {
        URL(string: "https://etherscan.io/address/\(address)")!
    }

    static func download(at address: String) throws {
        _ = try App.shared.safeRelayService.safeInfo(at: address)
    }

    static func exists(_ address: String) throws -> Bool {
        let context = CoreDataStack.shared.viewContext
        let fr = Safe.fetchRequest().by(address: address)
        let count = try context.count(for: fr)
        return count > 0
    }

    static func create(address: String, name: String, selected: Bool = true) {
        let context = CoreDataStack.shared.viewContext

        let safe = Safe(context: context)
        safe.address = address
        safe.name = name

        if selected {
            safe.select()
        }

        CoreDataStack.shared.saveContext()
    }

}

extension NSFetchRequest where ResultType == Safe {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \Safe.additionDate, ascending: true)]
        return self
    }

    func by(address: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "address CONTAINS[c] %@", address)
        fetchLimit = 1
        return self
    }

    func selected() -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "selection != nil")
        return self
    }
}
