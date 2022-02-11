//
//  CDWCConnection.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 08.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

/// CoreData object to persist information about the connections to other wallets and dapps
extension CDWCConnection {
    /// Find a connection by the url string
    ///
    /// - Parameter url: a connection URL
    /// - Returns: connection or nil if not foudn or encountered error
    static func connection(by url: String) -> CDWCConnection? {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fetchRequest = CDWCConnection.fetchRequest()
            fetchRequest.sortDescriptors = []
            fetchRequest.predicate = NSPredicate(format: "connectionURL == %@", url)
            fetchRequest.fetchLimit = 1
            let results = try context.fetch(fetchRequest)
            let result = results.first
            return result
        } catch {
            LogService.shared.error("Failed to fetch connection: \(error)")
            return nil
        }
    }

    // get all connections

    // get all expired connections (to remove it)?

    // get connection by wallet connect session

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

