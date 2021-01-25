//
//  App.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 27.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension AppSettings {
    static func current() -> AppSettings {
        dispatchPrecondition(condition: .onQueue(.main))
        do {
            let fr = AppSettings.fetchRequest().all()
            let result = try App.shared.coreDataStack.viewContext.fetch(fr)
            return result.first ?? AppSettings(context: App.shared.coreDataStack.viewContext)
        } catch {
            fatalError("Error fetching: \(error)")
        }
    }

    static var termsAccepted: Bool {
        set {
            dispatchPrecondition(condition: .onQueue(.main))
            current().termsAccepted = true
            App.shared.coreDataStack.saveContext()
        }
        get {
            dispatchPrecondition(condition: .onQueue(.main))
            return current().termsAccepted
        }
    }

    static var hasShownImportKeyOnboarding: Bool {
        set {
            dispatchPrecondition(condition: .onQueue(.main))
            current().importKeyOnBoardingShown = true
            App.shared.coreDataStack.saveContext()
        }
        get {
            dispatchPrecondition(condition: .onQueue(.main))
            return current().importKeyOnBoardingShown
        }
    }
}

extension NSFetchRequest where ResultType == AppSettings {
    func all() -> Self {
        sortDescriptors = []
        return self
    }
}
