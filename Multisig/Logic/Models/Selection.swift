//
//  AppSettings.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 20.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension Selection {

    class func selection() -> Selection? {
        dispatchPrecondition(condition: .onQueue(.main))
        do {
            let fr = Selection.fetchRequest().all()
            let result = try App.shared.coreDataStack.viewContext.fetch(fr)
            return result.first
        } catch {
            fatalError("Error fetching: \(error)")
        }
    }

    class func current() -> Selection {
        dispatchPrecondition(condition: .onQueue(.main))
        return selection() ?? Selection(context: App.shared.coreDataStack.viewContext)
    }

}

extension NSFetchRequest where ResultType == Selection {

    func all() -> Self {
        sortDescriptors = []
        return self
    }

}
