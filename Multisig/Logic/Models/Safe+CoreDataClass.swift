//
//  Safe+CoreDataClass.swift
//  
//
//  Created by Dmitry Bespalov on 06.05.20.
//
//

import Foundation
import CoreData

@objc(Safe)
public class Safe: NSManagedObject {
    var ensName: String?
    var threshold: UInt256?
    var implementation: Address?
    var version: String?
    var nonce: UInt256?
    var modules: [Address]?
    var fallbackHandler: Address?

    var safeAddress: Address? {
        address.flatMap { Address($0) }
    }

    var owners: [Address]? {
        get {
            guard let ownersData = ownersData else { return nil }
            return try? JSONDecoder().decode([Address].self, from: ownersData)
        }
        set {
            ownersData = try? JSONEncoder().encode(newValue)
        }
    }
}
