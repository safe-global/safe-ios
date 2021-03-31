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

    @AppSetting(\.fiatCode)
    private static var fiatCode: String?

    static var selectedFiatCode: String {
        get { fiatCode ?? "USD" }
        set { fiatCode = newValue }
    }
    
    @AppSetting(\.passcodeBannerDismissed)
    static var passcodeBannerDismissed: Bool

    @AppSetting(\.passcodeWasSetAtLeastOnce)
    static var passcodeWasSetAtLeastOnce: Bool

    @AppSetting(\.lastMarketingVersion)
    static var lastMarketingVersion: String?

    @AppSetting(\.lastBuildVersion)
    static var lastBuildVersion: String?

    static var isFreshInstall: Bool {
        // NOTE: historically, we didn't record the currently run
        // app version anywhere, but the termsAccepted exists since
        // the first app release, so this is a way to check for fresh install
        // even for the case when user upgrades their app to the new
        // release version.
        !termsAccepted
    }

    static var passcodeOptions: PasscodeOptions {
        get { PasscodeOptions(rawValue: rawPasscodeOptions) }
        set { rawPasscodeOptions = newValue.rawValue }
    }

    @AppSetting(\.passcodeOptions)
    private static var rawPasscodeOptions: Int64
}

extension AppSettings {
    static func saveCurrentRunVersionNumber() {
        Self.lastMarketingVersion = App.configuration.app.marketingVersion
        Self.lastBuildVersion = App.configuration.app.buildVersion
    }
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

struct PasscodeOptions: OptionSet {
    let rawValue: Int64

    static let useBiometry = PasscodeOptions(rawValue: 1 << 0)
    static let useForLogin = PasscodeOptions(rawValue: 1 << 1)
    static let useForConfirmation = PasscodeOptions(rawValue: 1 << 2)

    static let all: PasscodeOptions = [.useBiometry, .useForLogin, .useForConfirmation]
}
