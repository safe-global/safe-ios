//
//  SecuritySettings.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.01.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension SecuritySettings {
    // CoreData generated variables:

    // Defines whether security lock enabled or not
    // var isEnabled: Bool

    // Defines what type of lock method to use. See `LockMethod`
    // var lockMethodInt16: Int16

    /// Defines method to lock the app
    var lockMethod: LockMethod {
        get {
            LockMethod(rawValue: self.lockMethodInt16)!
        }
        set {
            self.lockMethodInt16 = newValue.rawValue
        }
    }

    // Whether to authenticate when app starts
    // var requiresForOpenApp: Bool

    // Whether to authenticate when using private keys (signing, export)
    // var requiresForUsingKeys: Bool

    static func current() -> SecuritySettings {
        dispatchPrecondition(condition: .onQueue(.main))
        do {
            let fr = SecuritySettings.fetchRequest()
            fr.sortDescriptors = []
            let result = try App.shared.coreDataStack.viewContext.fetch(fr)
            if let item = result.first {
                return item
            }
            let item = SecuritySettings(context: App.shared.coreDataStack.viewContext)
            item.isEnabled = false
            item.requiresForOpenApp = true
            item.requiresForUsingKeys = true
            return item
        } catch {
            fatalError("Error fetching: \(error)")
        }
    }

    func save() {
        if isEnabled {
            precondition(requiresForOpenApp || requiresForUsingKeys, "Either of requirements must be set")
        }
        App.shared.coreDataStack.saveContext()
    }
}

enum LockMethod: Int16 {
    case passcode = 0
    case userPresence = 1
    case passcodeAndUserPresence = 2
}
