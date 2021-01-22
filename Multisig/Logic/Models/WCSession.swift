//
//  WCSession.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 22.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData
import WalletConnectSwift

extension WCSession {
    static func getAll() throws -> [WCSession] {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fr = WCSession.fetchRequest().all()
            let sessions = try context.fetch(fr)
            return sessions
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    static func create(session: Session) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let wcSession = WCSession(context: context)
//        wcSession.created = Date()
        wcSession.peerId = session.dAppInfo.peerId
        wcSession.session = try! JSONEncoder().encode(session)
        App.shared.coreDataStack.saveContext()
    }

    static func remove(peerId: String) {
        let context = App.shared.coreDataStack.viewContext
        let fr = WCSession.fetchRequest().by(peerId: peerId)
        guard let session = try? context.fetch(fr).first else { return }
        context.delete(session)
        App.shared.coreDataStack.saveContext()
    }
}

extension NSFetchRequest where ResultType == WCSession {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \WCSession.created, ascending: true)]
        return self
    }

    func by(peerId: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "peerId CONTAINS[c] %@", peerId)
        fetchLimit = 1
        return self
    }
}
