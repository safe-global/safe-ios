//
//  CoreDataProtocol.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 03.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

protocol CoreDataProtocol {
    var persistentContainer: NSPersistentContainer { get }
    func saveContext()
    func rollback()
}

extension CoreDataProtocol {
    var viewContext: NSManagedObjectContext { persistentContainer.viewContext }
}
