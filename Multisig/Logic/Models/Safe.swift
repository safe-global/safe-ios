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
