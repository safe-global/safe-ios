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

    @AppSetting(\.onboardingCompleted)
    static var onboardingCompleted: Bool

    @AppSetting(\.trackingEnabled)
    static var trackingEnabled: Bool {
        didSet {
            Tracker.setTrackingEnabled(trackingEnabled)
        }
    }

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

    @AppSetting(\.copyAddressWithChainPrefix)
    static var copyAddressWithChainPrefix: Bool

    @AppSetting(\.prependingChainPrefixToAddresses)
    static var prependingChainPrefixToAddresses: Bool

    static var selectedFiatCode: String {
        get { fiatCode ?? "USD" }
        set { fiatCode = newValue }
    }

    @UserDefault(key: "io.gnosis.multisig.importKeyBannerWasShown")
    static var importKeyBannerWasShown: Bool?

    @UserDefault(key: "io.gnosis.multisig.safeTokenBannerWasShown")
    static var safeTokenBannerWasShown: Bool?

    @UserDefault(key: "io.gnosis.multisig.relayBannerWasShown")
    static var relayBannerWasShown: Bool?

    @AppSetting(\.lastMarketingVersion)
    static var lastMarketingVersion: String?

    @AppSetting(\.lastBuildVersion)
    static var lastBuildVersion: String?

    @AppSetting(\.securityCenterVersion)
    static var securityCenterVersion: Int32

    static var isFreshInstall: Bool {
        // NOTE: historically, we didn't record the currently run
        // app version anywhere, but the termsAccepted exists since
        // the first app release, so this is a way to check for fresh install
        // even for the case when user upgrades their app to the new
        // release version.
        !termsAccepted
    }

    // MARK: - Security & Passcode

    // TODO: make a group for security

    @AppSetting(\.passcodeBannerDismissed)
    static var passcodeBannerDismissed: Bool

    @AppSetting(\.passcodeWasSetAtLeastOnce)
    static var passcodeWasSetAtLeastOnce: Bool

    static var shouldOfferToSetupPasscode: Bool {
        get {
            !(passcodeBannerDismissed || passcodeWasSetAtLeastOnce)
        }
    }

    @AppSetting(\.securityLockEnabled)
    static var securityLockEnabled: Bool

    static var passcodeOptions: PasscodeOptions {
        get { PasscodeOptions(rawValue: rawPasscodeOptions) }
        set { rawPasscodeOptions = newValue.rawValue }
    }

    @AppSetting(\.passcodeOptions)
    private static var rawPasscodeOptions: Int64

    static var securityLockMethod: LockMethod {
        get { LockMethod(rawValue: rawLockMethod)! }
        set { rawLockMethod = newValue.rawValue }
    }


    @AppSetting(\.securityLockMethod)
    private static var rawLockMethod: Int16


    @AppSetting(\.lastIgnoredUpdateVersion)
    static var lastIgnoredUpdateVersion: String?

    @AppSetting(\.walletAppRegistryMigrationCompleted)
    static var walletAppRegistryMigrationCompleted: Bool
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

    // If user wants to enable biometry
    @available(iOS, deprecated: 14, message: "This option is deprecated. Please use `lockMethod` instead.")
    static let useBiometry = PasscodeOptions(rawValue: 1 << 0)

    // if user wants to authenticate on app opening
    static let useForLogin = PasscodeOptions(rawValue: 1 << 1)

    // if user wants to authenticate when using the private keys
    static let useForConfirmation = PasscodeOptions(rawValue: 1 << 2)

    static let all: PasscodeOptions = [.useBiometry, .useForLogin, .useForConfirmation]
}

enum LockMethod: Int16 {
    // authenticate with user-provided passcode
    case passcode = 0
    // authenticate with user's biometry (or device passcode, as a fallback)
    case userPresence = 1
    // authenticate with user-provided passcode and with user's biometry (or device passcode, as a fallback
    case passcodeAndUserPresence = 2

    func isPasscodeRequired() -> Bool {
        [.passcode, .passcodeAndUserPresence].contains(self)
    }

    func isUserPresenceRequired() -> Bool {
        [.userPresence, .passcodeAndUserPresence].contains(self)
    }
}

enum BiometryType {
    case faceID
    case touchID
    case passcode

    var name: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .passcode: return "Device Passcode"
        }
    }
}
