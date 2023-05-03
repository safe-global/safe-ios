//
//  SecurityCenter.swift
//  Multisig
//
//  Created by Mouaz on 1/4/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import LocalAuthentication
import Foundation
import CoreText
import CommonCrypto

class SecurityCenter {
    static let shared = SecurityCenter()

    private let sensitiveStore: ProtectedKeyStore
    private let dataStore: ProtectedKeyStore
    private static let version: Int32 = 1

    private static let appUnlockChallengeID = "global.safe.AppUnlockChallenge"
    private static let challenge = "I am not alive, but I grow; I don't have lungs, but I need air; I don't have a mouth, but water kills me. What am I?"


    var securityLockEnabled: Bool {
        AppSettings.securityLockEnabled
    }

    var lockMethod: LockMethod {
        get { AppSettings.securityLockMethod }
        set { AppSettings.securityLockMethod = newValue }
    }

    init(sensitiveStore: ProtectedKeyStore, dataStore: ProtectedKeyStore) {
        self.sensitiveStore = sensitiveStore
        self.dataStore = dataStore
    }

    private convenience init() {
        self.init(sensitiveStore: ProtectedKeyStore(protectionClass: .sensitive, KeychainItemStore()), dataStore: ProtectedKeyStore(protectionClass: .data, KeychainItemStore()))
    }

    func isDataStoreUnlocked() -> Bool {
        return dataStore.unlocked
    }

    func unlockDataStore(userPassword: String? = nil) throws {
        let derivedPasscode = userPassword != nil ? App.shared.securityCenter.derivedKey(from: userPassword!) : nil
        try dataStore.unlock(derivedPassword: derivedPasscode)
    }

    func lockDataStore() {
        dataStore.lock()
    }

    // MARK: - Business Logic Operations

    static func setUp()  {
        // clean up the left overs from the previous installation
        if AppSettings.isFreshInstall {
            /// This is needed because the Keychain doesn't get cleared when
            /// an app is removed from the phone. On the next installation
            /// all of the Keychain data will be present.
            ///
            /// The case when there are KeyInfo data (CoreData) are present but
            /// the Keychain data doesn't exist happens when users restore phones
            /// from the iCloud backup, which restores the application data but
            /// does not restore Keychain. It would not happen if a user would
            /// restore from encrypted backup, which restores Keychain data as well.
            reset()
        }

        do {
            try shared.initKeystores()
        } catch {
            LogService.shared.error("Failed to initialize keystores!", error: error)
        }

        //TODO: check version and perform migration
        if AppSettings.securityCenterVersion == 0 {
            migrateFromKeychainStorageToSecurityEnclave()
        } else if AppSettings.securityCenterVersion < version {
            // perform migration if needed
        }
        AppSettings.securityCenterVersion = version
    }

    static func reset() {
        do {
            try shared.sensitiveStore.deleteAllKeys()
            try shared.dataStore.deleteAllKeys()
        } catch {
            LogService.shared.error("Failed to delete previously installed keys", error: error)
        }
    }

    private static func migrateFromKeychainStorageToSecurityEnclave() {
        //TODO:
    }

    private func initKeystores() throws {
        if !sensitiveStore.isInitialized() {
            try sensitiveStore.initialize()
        }
        if !dataStore.isInitialized() {
            try dataStore.initialize()
            try dataStore.import(id: DataID(id: Self.appUnlockChallengeID), data: Self.challenge.data(using: .utf8)!)
        }
    }
    // change lock method:
        // passcode
            // old pass -> same pass
            // use biometry = false
        // userPresence
            // old pass is nil -> same pass
            // use biometry = true
        // passcode & user presence
            // old pass -> same pass
            // use biometry = true

    // change passcode:
        // use biometry = old use biometry
        // old pass -> new pass

    // TODO: only ask for passcode in create passcode if user declines face id

    // TODO: user-facing error handling

    // Requires:
    //  - AppSettings.lockMethod is set
    //  - passcode not nil if lockMethod is `.passcode` or `.passcodeAndUserPresence`, and nil if lockMethod is `.userPresence`
    //  - passcode is a plaintext passcode
    // Guarantees:
    //  - Sensitive store's encryption keys changed according to new options
    //  - Data store's encryption keys changed according to new options
    //     - Data store is only protected with user passcode when the lock method is `.passcode`
    func enableSecurityLock(passcode: String?) throws {
        do {
            AppSettings.passcodeOptions = [.useForLogin, .useForConfirmation]

            try changeStoreSettings(currentPlaintextPassword: nil, newPlaintextPassword: passcode, store: sensitiveStore)
            try changeStoreSettings(currentPlaintextPassword: nil, newPlaintextPassword: passcode, store: dataStore)

            AppSettings.securityLockEnabled = true
            AppSettings.passcodeWasSetAtLeastOnce = true

            Tracker.setPasscodeIsSet(to: true)
            Tracker.trackEvent(.userPasscodeEnabled)

            NotificationCenter.default.post(name: .passcodeCreated, object: nil)
        } catch {
            AppSettings.passcodeOptions = []
            throw error
        }
    }

    // Requires:
    //  - if newMethod does not require passcode, then `newPasscode` must be nil.
    func changeLockMethod(oldMethod: LockMethod, newMethod: LockMethod, newPasscode: String?, completion: @escaping (Error?) -> Void) {
        requestPassword(for: [.sensitive, .data]) { [unowned self] oldPasscode in
            do {
                var changedPasscode = newPasscode

                if oldMethod.isPasscodeRequired() {
                    changedPasscode = oldPasscode
                }

                AppSettings.securityLockMethod = newMethod

                // Change settings should be done only for the enabled store
                // Change settings for disabled store will throw an exception
                if AppSettings.passcodeOptions.contains(.useForConfirmation) {
                    try changeStoreSettings(currentPlaintextPassword: oldPasscode,
                                            newPlaintextPassword: changedPasscode,
                                            store: sensitiveStore)
                }

                if AppSettings.passcodeOptions.contains(.useForLogin) {
                    try changeStoreSettings(currentPlaintextPassword: oldPasscode,
                                            newPlaintextPassword: changedPasscode,
                                            store: dataStore)
                }

                completion(nil)
            } catch {
                AppSettings.securityLockMethod = oldMethod
                completion(error)
            }
        }
    }

    /// Checks if the passcode correct. In case passcode is not set, returns false.
    /// - Parameter plaintextPasscode: unsecured "as-is" passcode
    /// - Returns: true if passcode correct, false otherwise
    func isPasscodeCorrect(plaintextPasscode: String) throws -> Bool {
        let derivedPasscode = App.shared.securityCenter.derivedKey(from: plaintextPasscode)
        return try dataStore.find(dataID: DataID(id: Self.appUnlockChallengeID), password: derivedPasscode, forceUnlock: true) != nil
    }

    func changePasscode(oldPasscode: String, newPasscode: String) throws {
        if AppSettings.passcodeOptions.contains(.useForConfirmation) {
            try changeStoreSettings(currentPlaintextPassword: oldPasscode,
                                    newPlaintextPassword: newPasscode,
                                    store: sensitiveStore)
        }

        if AppSettings.passcodeOptions.contains(.useForLogin) {
            try changeStoreSettings(currentPlaintextPassword: oldPasscode,
                                    newPlaintextPassword: newPasscode,
                                    store: dataStore)
        }
    }

    func toggleUsage(passcodeOption: PasscodeOptions, completion: @escaping (Error?) -> Void) {
        let enabledOptions = AppSettings.passcodeOptions

        let bothTogglesWillBeOff = AppSettings.passcodeOptions.contains(passcodeOption) &&
            AppSettings.passcodeOptions
                .subtracting(passcodeOption)
                .isDisjoint(with: [.useForLogin, .useForConfirmation])

        if bothTogglesWillBeOff {
            disableSecurityLock(completion: completion)
            return
        }

        let protectionClass: ProtectionClass = passcodeOption == .useForLogin ? .data : .sensitive
        let protectedKeyStore: ProtectedKeyStore = passcodeOption == .useForLogin ? dataStore : sensitiveStore

        let toggleWillBeOff: Bool = enabledOptions.contains(passcodeOption)
        if toggleWillBeOff {
            requestPassword(for: [protectionClass]) { [unowned self] plaintextPasscode in
                do {
                    AppSettings.passcodeOptions.remove(passcodeOption)
                    try changeStoreSettings(currentPlaintextPassword: plaintextPasscode,
                                            newPlaintextPassword: nil,
                                            store: protectedKeyStore)
                    completion(nil)
                } catch {
                    AppSettings.passcodeOptions.remove(passcodeOption)
                    completion(parse(error: error))
                }
            }
        } else {
            let otherProtectionClass: ProtectionClass = protectionClass == .sensitive ? .data : .sensitive
            let otherProtectedKeyStore: ProtectedKeyStore = otherProtectionClass == .data ? dataStore : sensitiveStore

            requestPassword(for: [otherProtectionClass]) { [unowned self] plaintextPasscode in
                do {
                    let currentDerivedPassword = plaintextPasscode.map { derivedKey(from: $0) }
                    try otherProtectedKeyStore.authenticate(password: currentDerivedPassword)
                    AppSettings.passcodeOptions.insert(passcodeOption)

                    try changeStoreSettings(currentPlaintextPassword: nil,
                                            newPlaintextPassword: plaintextPasscode,
                                            store: protectedKeyStore)
                    completion(nil)
                } catch {
                    AppSettings.passcodeOptions.remove(passcodeOption)
                    completion(parse(error: error))
                }
            }
        }
    }

    // TODO: we need to keep the dataStore unlocked when the app is in foreground, i.e. to unlock it once:
        // when the lock is enabled -> app becomes unlocked
        // when the app enters foreground and unlocks -> then it's OK.

    fileprivate func changeStoreSettings(currentPlaintextPassword: String?, newPlaintextPassword: String?, store: ProtectedKeyStore) throws {
        let currentDerivedPassword = currentPlaintextPassword.map { derivedKey(from: $0) }
        let newDerivedPassword = newPlaintextPassword.map { derivedKey(from: $0) }

        let newStorePassword: String?
        let biometryUsed: Bool

        let optionForStore: PasscodeOptions = store === sensitiveStore ? .useForConfirmation : .useForLogin
        let isStoreLockEnabled: Bool = AppSettings.passcodeOptions.contains(optionForStore)

        if isStoreLockEnabled {
            // sensitive store can ask passcode and biometrics to access the items, depending on the lock method.
            // data store only asks for passcode if that's the lock method. Otherwise, it uses biometric authentication.
            let lockMethodsWithPassword: [LockMethod] = store === sensitiveStore ? [.passcode, .passcodeAndUserPresence] : [.passcode]
            
            newStorePassword = lockMethodsWithPassword.contains(AppSettings.securityLockMethod) ? newDerivedPassword! : nil
            biometryUsed = AppSettings.securityLockMethod.isUserPresenceRequired()
        } else {
            newStorePassword = nil
            biometryUsed = false
        }
        try store.changePassword(from: currentDerivedPassword, to: newStorePassword, useBiometry: biometryUsed, keepUnlocked: store.protectionClass == .data)
    }

    // TODO: cancelling is not an error? success = false means cancelled?
    // Requires:
    //  - AppSettings.securityLockEnabled is true
    //  - AppSettings.lockMethod and AppSettings.passcodeOptions are current
    // Guarantees:
    //  - If user enters correct passcode & biometrics (when needed), then the passcode and biometrics are disabled.
    //    AND the completion block is called with 'nil' result
    //  - If user enters wrong passcode or biometrics OR cancels authentication, then the completion is called with error result.
    func disableSecurityLock(authenticate: Bool = true, completion: @escaping (Error?) -> ()) {
        let oldOptions = AppSettings.passcodeOptions

        if authenticate {
            requestPassword(for: [.sensitive, .data]) { [unowned self] plaintextPasscode in
                do {
                    if AppSettings.passcodeOptions.contains(.useForConfirmation) {
                        AppSettings.passcodeOptions.remove(.useForConfirmation)
                        try changeStoreSettings(currentPlaintextPassword: plaintextPasscode,
                                                newPlaintextPassword: nil,
                                                store: sensitiveStore)
                    }

                    if AppSettings.passcodeOptions.contains(.useForLogin) {
                        AppSettings.passcodeOptions.remove(.useForLogin)
                        try changeStoreSettings(currentPlaintextPassword: plaintextPasscode,
                                                newPlaintextPassword: nil,
                                                store: dataStore)
                    }

                    AppSettings.securityLockEnabled = false
                    completion(nil)
                } catch {
                    AppSettings.passcodeOptions = oldOptions
                    completion(parse(error: error))
                }
            }
        } else {
            Self.reset()
            Self.setUp()
            AppSettings.passcodeOptions = []
            AppSettings.securityLockEnabled = false
            completion(nil)
        }

    }

    func shouldShowPasscode(for accessScope: [ProtectionClass] = [.data, .sensitive]) -> Bool {
        return AppSettings.securityLockEnabled &&
        (
            accessScope.contains(.sensitive) && AppSettings.passcodeOptions.contains(.useForConfirmation) && [LockMethod.passcode, .passcodeAndUserPresence].contains(AppSettings.securityLockMethod) ||
            accessScope.contains(.data) && AppSettings.passcodeOptions.contains(.useForLogin) && [LockMethod.passcode].contains(AppSettings.securityLockMethod)
        )
    }

    func shouldShowFaceID(for accessScope: [ProtectionClass] = [.data, .sensitive]) -> Bool {
        return AppSettings.securityLockEnabled &&
        (
            accessScope.contains(.sensitive) && AppSettings.passcodeOptions.contains(.useForConfirmation) && [LockMethod.userPresence].contains(AppSettings.securityLockMethod) ||
            accessScope.contains(.data) && AppSettings.passcodeOptions.contains(.useForLogin) && [LockMethod.userPresence].contains(AppSettings.securityLockMethod)
        )
    }

    private func requestPassword(for accessScope: [ProtectionClass], task: @escaping (_ plaintextPasscode: String?) -> Void) {

        let needsUserPasscode =
            AppSettings.securityLockEnabled &&
            (
                accessScope.contains(.sensitive) && AppSettings.passcodeOptions.contains(.useForConfirmation) && [LockMethod.passcode, .passcodeAndUserPresence].contains(AppSettings.securityLockMethod) ||
                accessScope.contains(.data) && AppSettings.passcodeOptions.contains(.useForLogin) && [LockMethod.passcode].contains(AppSettings.securityLockMethod)
            )

        if needsUserPasscode {
            NotificationCenter.default.post(name: .passcodeRequired,
                                            object: self,
                                            userInfo: ["accessTask": task])
        } else {
            task(nil)
        }
    }

    /// Import data potentially overriding existing value
    ///
    /// - Parameters:
    ///   - id:  data id
    ///   - data: data to protect
    ///   - completion: callback returns success(true) if import successfull, success(false) if operation was canceled by user, or failure otherwise.
    func `import`(id: DataID, data: Data, protectionClass: ProtectionClass = .sensitive, completion: @escaping (Result<Bool, Error>) -> ()) {
        let store: ProtectedKeyStore = protectionClass == .sensitive ? sensitiveStore : dataStore
        do {
            try store.import(id: id, data: data)
            completion(.success(true))
        } catch {
            completion(.failure(parse(error: error)))
        }
    }

    /// Remove data from keystore
    ///
    /// - Parameters:
    ///   - dataID: data id
    ///   - protectionClass: which keystore to use for removal: sensitive or data
    ///   - completion: callback returns success(true) if import successfull, success(false) if operation was canceled by user, or failure otherwise.
    func remove(dataID: DataID, protectionClass: ProtectionClass = .sensitive, authenticate: Bool = true, completion: @escaping (Result<Bool, Error>) -> ()) {
        let store: ProtectedKeyStore = protectionClass == .sensitive ? sensitiveStore : dataStore
        if authenticate {
            requestPassword(for: [protectionClass]) { [unowned self] plaintextPassword in
                do {
                    let password = plaintextPassword.map { derivedKey(from: $0) }
                    try store.authenticate(password: password)
                    try store.delete(id: dataID)
                    completion(.success(true))
                } catch {
                    completion(.failure(parse(error: error)))
                }
            }
        } else {
            do {
                try store.delete(id: dataID)
                completion(.success(true))
            } catch {
                completion(.failure(parse(error: error)))
            }
        }
    }

    func find(dataID id: DataID, protectionClass: ProtectionClass = .sensitive, completion: @escaping (Result<Data?, Error>) -> ()) {
        let store: ProtectedKeyStore = protectionClass == .sensitive ? sensitiveStore : dataStore

        requestPassword(for: [protectionClass]) { [unowned self] plaintextPassword in
            do {
                let password = plaintextPassword.map { derivedKey(from: $0) }
                let data = try store.find(dataID: id, password: password)
                completion(.success(data))
            } catch {
                completion(.failure(parse(error: error)))
            }
        }
    }

    func derivedKey(from plaintext: String, useOldSalt: Bool = false) -> String {
        let salt = salt(oldSalt: useOldSalt)
        var derivedKey = [UInt8](repeating: 0, count: 256 / 8)
        let result = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            plaintext,
            plaintext.lengthOfBytes(using: .utf8),
            salt,
            salt.lengthOfBytes(using: .utf8),
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            100_000,
            &derivedKey,
            derivedKey.count)
        guard result == kCCSuccess else {
            LogService.shared.error("Failed to derive key", error: "Failed to derive a key: \(result)")
            return plaintext
        }
        return Data(derivedKey).toHexString()
    }

    // For backward compatibility we need to use both salts for some cases
    private func salt(oldSalt: Bool = false) -> String {
        oldSalt ? "Gnosis Safe Multisig Passcode Salt" : "Safe Multisig Passcode Salt"
    }

    func parse(error: Error) -> Error {
        guard let nsError = error as? NSError else {
            return GSError.KeychainError(reason: error.localizedDescription)
        }

        // User cancel operation
        if nsError.code == LAError.userCancel.rawValue {
            return GSError.CancelledByUser()
        }

        return GSError.KeychainError(reason: error.localizedDescription)
    }
}

// SecCenter -> find -> receive pass -> try store.find() -> completed
// SecCent -> find -> receive pass -> try store.find() -> error -> try store.find() ->
