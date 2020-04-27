//
//  SafeMO.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 15.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension Safe {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.createdAt = Date()
    }

    func save() {
        CoreDataStack.shared.saveContext()
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

    static func exists(at address: Address) throws -> Bool {
        let stringAddress = address.hex(eip55: true)
        do {
            _ = try App.shared.safeRelayService.safeInfo(at: stringAddress)
            return true
        } catch let HTTPClient.Error.networkRequestFailed(request, response, data) {
            if (response as? HTTPURLResponse)?.statusCode == 404 {
                return false
            }

            struct BackendException: Codable {
                var exception: String

                var isSafeNotDeployed: Bool {
                    exception.starts(with: "SafeNotDeployed:")
                }
            }

            if let data = data,
                let exception = try? JSONDecoder().decode(
                    BackendException.self, from: data
                ),
                exception.isSafeNotDeployed {
                return false
            }

            throw HTTPClient.Error.networkRequestFailed(request, response, data)
        }
    }
}
