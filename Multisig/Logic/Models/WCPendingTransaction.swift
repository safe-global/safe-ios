//
//  PendingWCTransaction.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 04.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension WCPendingTransaction {
    static func getAll() throws -> [WCPendingTransaction] {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fr = WCPendingTransaction.fetchRequest().all()
            let transactions = try context.fetch(fr)
            return transactions
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    static func create(wcSession: WCSession, nonce: UInt256String, requestId: String) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let pendingTransaction = WCPendingTransaction(context: context)
        pendingTransaction.session = wcSession
        pendingTransaction.nonce = nonce.description
        pendingTransaction.requestId = requestId
        App.shared.coreDataStack.saveContext()
    }

    static func remove(nonce: String) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = WCPendingTransaction.fetchRequest().by(nonce: nonce)
        guard let transaction = try? context.fetch(fr).first else { return }
        context.delete(transaction)
        App.shared.coreDataStack.saveContext()
    }
}

extension NSFetchRequest where ResultType == WCPendingTransaction {
    func all() -> Self {
        sortDescriptors = []
        return self
    }

    func by(nonce: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "nonce CONTAINS[c] %@", nonce)
        fetchLimit = 1
        return self
    }
}
