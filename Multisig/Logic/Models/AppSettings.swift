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

    @AppSetting(\.termsAccepted)
    static var termsAccepted: Bool

    @AppSetting(\.importKeyOnBoardingShown)
    static var hasShownImportKeyOnboarding: Bool

    @AppSetting(\.dismissedImportKeyBanner)
    static var importKeyBannerDismissed: Bool

    @AppSetting(\.importedOwnerKey)
    static var importedOwnerKey: Bool

    @AppSetting(\.appReviewEventCount)
    static var appReviewEventCount: Int64

    @AppSetting(\.displayMode)
    static var displayMode: Int32

    @AppSetting(\.passcodeBannerDismissed)
    static var passcodeBannerDismissed: Bool

    @AppSetting(\.passcodeWasSetAtLeastOnce)
    static var passcodeWasSetAtLeastOnce: Bool
}

extension NSFetchRequest where ResultType == AppSettings {
    func all() -> Self {
        sortDescriptors = []
        return self
    }
}

@propertyWrapper
struct AppSetting<T> {
    private var path: ReferenceWritableKeyPath<AppSettings, T>

    init(_ path: ReferenceWritableKeyPath<AppSettings, T>) {
        self.path = path
    }

    var wrappedValue: T {
        get {
            dispatchPrecondition(condition: .onQueue(.main))
            let object = AppSettings.current()
            return object[keyPath: path]
        }
        set {
            dispatchPrecondition(condition: .onQueue(.main))
            let object = AppSettings.current()
            object[keyPath: path] = newValue
            App.shared.coreDataStack.saveContext()
        }
    }
}
