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

    var threshold: Int?
    var owners: [String]?
    var masterCopy: String?
    var version: String?
    var nonce: Int?
    var modules: [String]?
    var fallbackHandler: String?

}
