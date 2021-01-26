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
    enum WCSessionStatus: Int {
        case connecting = 0, connected
    }

    var status: WCSessionStatus {
        get {
            WCSessionStatus(rawValue: Int(statusRaw))!
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
        let context = App.shared.coreDataStack.viewContext
        let wcSession = WCSession(context: context)
        wcSession.status = .connecting
        wcSession.created = Date()
        wcSession.topic = wcurl.topic
        App.shared.coreDataStack.saveContext()
    }

    static func update(session: Session, status: WCSessionStatus) {
        let context = App.shared.coreDataStack.viewContext
        let fr = WCSession.fetchRequest().by(topic: session.url.topic)
        guard let wcSession = try? context.fetch(fr).first else { return }
        wcSession.status = status
        wcSession.session = try! JSONEncoder().encode(session)
        App.shared.coreDataStack.saveContext()
    }

    static func remove(topic: String) {
        let context = App.shared.coreDataStack.viewContext
        let fr = WCSession.fetchRequest().by(topic: topic)
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

    func by(topic: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "topic CONTAINS[c] %@", topic)
        fetchLimit = 1
        return self
    }
}

extension Session {
    static func from(_ wcSession: WCSession) throws -> Self {        
        let decoder = JSONDecoder()
        return try decoder.decode(Session.self, from: wcSession.session!)
    }
}
