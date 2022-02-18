//
//  CDWCConnection.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 08.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

/// CoreData object to persist information about the connections to other wallets and dapps
extension CDWCConnection {
    /// Find a connection by the url string
    ///
    /// - Parameter url: a connection URL
    /// - Returns: connection or nil if not foudn or encountered error
    static func connection(by url: String) -> CDWCConnection? {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fetchRequest = CDWCConnection.fetchRequest().by(url: url)
            let results = try context.fetch(fetchRequest)
            let result = results.first
            return result
        } catch {
            LogService.shared.error("Failed to fetch connection: \(error)")
            return nil
        }
    }

    // get all connections
    static func getAll() throws -> [CDWCConnection] {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fr = CDWCConnection.fetchRequest().all()
            let connections = try context.fetch(fr)
            return connections
        } catch {
            throw GSError.DatabaseError(reason: error.localizedDescription)
        }
    }

    static func connections(by status: Int16) -> [CDWCConnection] {
        let predicate = NSPredicate(format: "status == %@", NSNumber(value: status))
        let results = connections(predicate: predicate)
        return results
    }

    static func connections(expiredAt date: Date) -> [CDWCConnection] {
        connections(predicate: NSPredicate(format: "!(expirationDate = nil) AND expirationDate <= %@", date as NSDate))
    }

    private static func connections(predicate: NSPredicate) -> [CDWCConnection] {
        let results: [CDWCConnection]
        do {
            let context = App.shared.coreDataStack.viewContext
            let fetchRequest = CDWCConnection.fetchRequest().all()
            fetchRequest.predicate = predicate
            results = try context.fetch(fetchRequest)
        } catch {
            LogService.shared.error("Failed to fetch connection: \(error)")
            results = []
        }
        return results
    }

    /// Creates new connection without saving it in the database
    static func create() -> CDWCConnection {
        let context = App.shared.coreDataStack.viewContext
        let result = CDWCConnection(context: context)
        return result
    }

    /// Deletes a connection if it exists. Idempotent.
    ///
    /// - Parameter url: connection URL
    static func delete(by url: String) {
        let context = App.shared.coreDataStack.viewContext
        if let connection = connection(by: url) {
            context.delete(connection)
        }
        App.shared.coreDataStack.saveContext()
    }

    // update connection with network, address

}

extension NSFetchRequest where ResultType == CDWCConnection {
    func all() -> Self {
        sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: true)]
        return self
    }

    func by(url: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "connectionURL == %@", url)
        fetchLimit = 1
        return self
    }
}
