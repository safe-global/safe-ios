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
import WalletConnectUtils
import WalletConnectSign

extension WCSession {
    var status: SessionStatus {
        get {
            SessionStatus(rawValue: Int(statusRaw))!
        } set {
            statusRaw = Int16(newValue.rawValue)
        }
    }

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

    static func get(topic: String) -> WCSession? {
        let context = App.shared.coreDataStack.viewContext
        let fr = WCSession.fetchRequest().by(topic: topic)
        return try? context.fetch(fr).first
    }

    static func create(wcurl: WCURL) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let safe = try? Safe.getSelected() else { return }

        let wcSession: WCSession
        if let existing = get(topic: wcurl.topic) {
            wcSession = existing
        } else {
            let context = App.shared.coreDataStack.viewContext
            wcSession = WCSession(context: context)
        }

        wcSession.status = .connecting
        wcSession.created = Date()
        wcSession.topic = wcurl.topic
        wcSession.safe = safe
        
        App.shared.coreDataStack.saveContext()
    }

    static func create(uri: WalletConnectURI) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let safe = try? Safe.getSelected() else { return }

        let wcSession: WCSession
        if let existing = get(topic: uri.topic) {
            wcSession = existing
        } else {
            let context = App.shared.coreDataStack.viewContext
            wcSession = WCSession(context: context)
        }

        wcSession.status = .connecting
        wcSession.created = Date()
        wcSession.topic = uri.topic
        wcSession.safe = safe

        App.shared.coreDataStack.saveContext()
    }
    
    static func update(session: WalletConnectSwift.Session, status: SessionStatus) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let fr = WCSession.fetchRequest().by(topic: session.url.topic)
        guard let wcSession = try? context.fetch(fr).first else { return }
        wcSession.status = status
        wcSession.session = try! JSONEncoder().encode(session)
        App.shared.coreDataStack.saveContext()
    }

    func delete() {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        context.delete(self)
        App.shared.coreDataStack.saveContext()
    }
}

extension NSFetchRequest where ResultType == WCSession {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(keyPath: \WCSession.created, ascending: true)]
        return self
    }

    func by(topic: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "topic == %@", topic)
        fetchLimit = 1
        return self
    }
}

extension WalletConnectSwift.Session {
    static func from(_ wcSession: WCSession) throws -> Self {        
        let decoder = JSONDecoder()
        return try decoder.decode(Session.self, from: wcSession.session!)
    }
}
