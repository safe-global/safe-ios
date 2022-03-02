//
//  CDEthTransaction.swift
//  Multisig
//
//  Created by Moaaz on 2/25/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension CDEthTransaction {
    static var all: [CDEthTransaction] {
        let context = App.shared.coreDataStack.viewContext
        return (try? context.fetch(CDEthTransaction.fetchRequest().all())) ?? []
    }

    static func by(safeAddresses: [String], chainId: String) -> [CDEthTransaction] {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        return (try? safeAddresses.compactMap { address in
            let fr = CDEthTransaction.fetchRequest().by(safeAddress: address, chainId: chainId)
            let items = try context.fetch(fr)
            return items.first
        }) ?? []
    }
}


extension NSFetchRequest where ResultType == CDEthTransaction {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(key: "dateSubmittedAt", ascending: true)]
        return self
    }

    func by(safeAddress: String, chainId: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "safeAddress == %@ AND chainId == %@", safeAddress, chainId)
        fetchLimit = 1
        return self
    }
}
