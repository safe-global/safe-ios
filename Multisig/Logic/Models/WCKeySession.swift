//
//  WCKeySession.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 09.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData
import WalletConnectSwift

extension WCKeySession {
    var status: SessionStatus {
        get {
            SessionStatus(rawValue: Int(statusRaw))!
        } set {
            statusRaw = Int16(newValue.rawValue)
        }
    }

    static func getAll() throws -> [WCKeySession] {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fr = WCKeySession.fetchRequest().all()
            let sessions = try context.fetch(fr)
            return sessions
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    static func get(topic: String) -> WCKeySession? {
        let context = App.shared.coreDataStack.viewContext
        let fr = WCKeySession.fetchRequest().by(topic: topic)
        return try? context.fetch(fr).first
    }

    static func create(wcurl: WCURL) {
        dispatchPrecondition(condition: .onQueue(.main))

        let wcKeySession: WCKeySession
        if let existing = get(topic: wcurl.topic) {
            wcKeySession = existing
        } else {
            let context = App.shared.coreDataStack.viewContext
            wcKeySession = WCKeySession(context: context)
        }

        wcKeySession.status = .connecting
        wcKeySession.created = Date()
        wcKeySession.topic = wcurl.topic

        App.shared.coreDataStack.saveContext()
    }

    static func update(session: Session, status: SessionStatus) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = WCKeySession.fetchRequest().by(topic: session.url.topic)
        guard let wcKeySession = try? context.fetch(fr).first else { return }
        wcKeySession.status = status
        wcKeySession.session = try! JSONEncoder().encode(session)
        App.shared.coreDataStack.saveContext()
    }

    func delete() {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        context.delete(self)
        App.shared.coreDataStack.saveContext()
    }
}

extension NSFetchRequest where ResultType == WCKeySession {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \WCKeySession.created, ascending: true)]
        return self
    }

    func by(topic: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "topic == %@", topic)
        fetchLimit = 1
        return self
    }
}

extension Session {
    static func from(_ wcKeySession: WCKeySession) throws -> Self {
        let decoder = JSONDecoder()
        return try decoder.decode(Session.self, from: wcKeySession.session!)
    }
}
