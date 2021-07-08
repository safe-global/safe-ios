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
    var version: String?
    var nonce: UInt256?
    var addressInfo: AddressInfo?
    var ownersInfo: [AddressInfo]?
    var implementationInfo: AddressInfo?
    var modulesInfo: [AddressInfo]?
    var fallbackHandlerInfo: AddressInfo?
    var guardInfo: AddressInfo?
}
