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

    static func acceptTerms() {
        dispatchPrecondition(condition: .onQueue(.main))
        let appSettings = current()
        appSettings.termsAccepted = true
        App.shared.coreDataStack.saveContext()
    }

    static func hasAcceptedTerms() -> Bool {
        dispatchPrecondition(condition: .onQueue(.main))
        let appSettings = current()
        return appSettings.termsAccepted
    }

    static func setSigningKeyAddress(_ key: String?) {
        dispatchPrecondition(condition: .onQueue(.main))
        let appSettings = current()
        appSettings.signingKeyAddress = key
        App.shared.coreDataStack.saveContext()
    }
}

extension NSFetchRequest where ResultType == AppSettings {
    func all() -> Self {
        sortDescriptors = []
        return self
    }
}
