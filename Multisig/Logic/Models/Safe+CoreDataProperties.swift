//
//  Safe+CoreDataProperties.swift
//  
//
//  Created by Dmitry Bespalov on 06.05.20.
//
//

import Foundation
import CoreData

extension Safe {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Safe> {
        return NSFetchRequest<Safe>(entityName: "Safe")
    }

    @NSManaged public var additionDate: Date?
    @NSManaged public var address: String?
    @NSManaged public var name: String?
    @NSManaged public var selection: Selection?
    @NSManaged public var network: Network?
}
