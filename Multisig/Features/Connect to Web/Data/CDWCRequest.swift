//
// Created by Dmitry Bespalov on 16.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension CDWCRequest {

    static func all() -> [CDWCRequest] {
        requests()
    }

    // all requests with opened connections and this status sorted by creation date
    static func all(status: Int16) -> [CDWCRequest] {
        requests(predicate: NSPredicate(format: "status == %@ AND connection.status == %@", NSNumber(value: status), NSNumber(value: WebConnectionStatus.opened.rawValue)))
    }

    static func all(url: String, status: Int16) -> [CDWCRequest] {
        requests(predicate: NSPredicate(format: "status = %@ AND connection.connectionURL = %@", NSNumber(value: status), url))
    }

    static func request(url: String, id_int: Int64, id_double: Double, id_string: String?) -> CDWCRequest? {
        let predicate = NSPredicate(format: "connection.connectionURL == %@ AND id_int == %@ AND id_double == %@ AND id_string == %@", url, NSNumber(value: id_int), NSNumber(value: id_double), id_string ?? NSNull())
        let result = request(predicate: predicate)
        return result
    }

    fileprivate static func request(predicate: NSPredicate) -> CDWCRequest? {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fetchRequest = CDWCRequest.fetchRequest()
            fetchRequest.predicate = predicate
            fetchRequest.fetchLimit = 1
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "createdDate", ascending: false)
            ]
            let result = try context.fetch(fetchRequest).first
            return result
        } catch {
            LogService.shared.error("Failed to get existing request from CoreData: \(error)")
            return nil
        }
    }

    fileprivate static func requests(predicate: NSPredicate? = nil) -> [CDWCRequest] {
        do {
            let context = App.shared.coreDataStack.viewContext
            let fetchRequest = CDWCRequest.fetchRequest()
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "createdDate", ascending: true)
            ]
            let result = try context.fetch(fetchRequest)
            return result
        } catch {
            LogService.shared.error("Failed to get existing request from CoreData: \(error)")
            return []
        }
    }

    static func request(connectionURL: WebConnectionURL, method: String, status: WebConnectionRequestStatus) -> CDWCRequest? {
        let predicate = NSPredicate(
            format: "connection.connectionURL == %@ AND method == %@ AND status == %@",
            connectionURL.absoluteString,
            method,
            NSNumber(value: status.rawValue)
        )
        let result = request(predicate: predicate)
        return result
    }

    static func create() -> CDWCRequest {
        let context = App.shared.coreDataStack.viewContext
        let result = CDWCRequest(context: context)
        return result
    }

    static func delete(url: String, id_int: Int64, id_double: Double, id_string: String?) {
        let context = App.shared.coreDataStack.viewContext
        if let object = request(url: url, id_int: id_int, id_double: id_double, id_string: id_string) {
            context.delete(object)
        }
        App.shared.coreDataStack.saveContext()
    }
}
