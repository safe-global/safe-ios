//
//  SecurityCenter.swift
//  Multisig
//
//  Created by Mouaz on 1/4/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

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
            do {
                try shared.sensitiveStore.deleteAllKeys()
                try shared.dataStore.deleteAllKeys()
            } catch {
                LogService.shared.error("Failed to delete previously installed keys", error: error)
            }
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

    func changePasscode(oldPasscode: String, newPasscode: String) throws {
        try changeStoreSettings(currentPlaintextPassword: oldPasscode, newPlaintextPassword: newPasscode, store: sensitiveStore)
        try changeStoreSettings(currentPlaintextPassword: oldPasscode, newPlaintextPassword: newPasscode, store: dataStore)
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
            let lockMethodsWithBiometry: [LockMethod] = [.userPresence, .passcodeAndUserPresence]

            newStorePassword = lockMethodsWithPassword.contains(AppSettings.securityLockMethod) ? newDerivedPassword! : nil
            biometryUsed = lockMethodsWithBiometry.contains(AppSettings.securityLockMethod)
        } else {
            newStorePassword = nil
            biometryUsed = false
        }
        try store.changePassword(from: currentDerivedPassword, to: newStorePassword, useBiometry: biometryUsed)
    }

    // TODO: cancelling is not an error? success = false means cancelled?
    // Requires:
    //  - AppSettings.securityLockEnabled is true
    //  - AppSettings.lockMethod and AppSettings.passcodeOptions are current
    // Guarantees:
    //  - If user enters correct passcode & biometrics (when needed), then the passcode and biometrics are disabled.
    //    AND the completion block is called with 'nil' result
    //  - If user enters wrong passcode or biometrics OR cancels authentication, then the completion is called with error result.
    func disableSecurityLock(completion: @escaping (Error?) -> ()) {
        let oldOptions = AppSettings.passcodeOptions

        requestPasswordV2(for: [.sensitive, .data]) { [unowned self] plaintextPasscode in
            // disable all locks
            AppSettings.passcodeOptions = []

            try changeStoreSettings(currentPlaintextPassword: plaintextPasscode, newPlaintextPassword: nil, store: sensitiveStore)
            try changeStoreSettings(currentPlaintextPassword: plaintextPasscode, newPlaintextPassword: nil, store: dataStore)
            completion(nil)
        } onFailure: { error in
            AppSettings.passcodeOptions = oldOptions
            completion(error)
        }
    }

    private func requestPasswordV2(for accessScope: [ProtectionClass], task: @escaping (_ plaintextPasscode: String?) throws -> Void, onFailure: @escaping (_ error: Error) -> Void) {
        let needsUserPasscode =
            AppSettings.securityLockEnabled &&
            (
                accessScope.contains(.sensitive) && AppSettings.passcodeOptions.contains(.useForConfirmation) && [LockMethod.passcode, .passcodeAndUserPresence].contains(AppSettings.securityLockMethod) ||
                accessScope.contains(.data) && AppSettings.passcodeOptions.contains(.useForLogin) && [LockMethod.passcode].contains(AppSettings.securityLockMethod)
            )

        if needsUserPasscode {
            NotificationCenter.default.post(name: .passcodeRequired,
                                            object: self,
                                            userInfo: ["accessTask": task, "onFailure": onFailure])
        } else {
            do {
                try task(nil)
            } catch {
                onFailure(error)
            }
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
        } catch let error {
            completion(.failure(GSError.KeychainError(reason: error.localizedDescription)))
        }
    }

    /// Remove data from keystore
    ///
    /// - Parameters:
    ///   - dataID: data id
    ///   - protectionClass: which keystore to use for removal: sensitive or data
    ///   - completion: callback returns success(true) if import successfull, success(false) if operation was canceled by user, or failure otherwise.
    func remove(dataID: DataID, protectionClass: ProtectionClass = .sensitive, completion: @escaping (Result<Bool, Error>) -> ()) {
        let store: ProtectedKeyStore = protectionClass == .sensitive ? sensitiveStore : dataStore
        do {
            try store.delete(id: dataID)
            completion(.success(true))
        } catch let error {
            completion(.failure(GSError.KeychainError(reason: error.localizedDescription)))
        }
    }

    func find(dataID id: DataID, protectionClass: ProtectionClass = .sensitive, completion: @escaping (Result<Data?, Error>) -> ()) {
        let store: ProtectedKeyStore = protectionClass == .sensitive ? sensitiveStore : dataStore
        requestPassword(scope: [protectionClass]) { [unowned self] plaintextPassword in
            let password = plaintextPassword.map { derivedKey(from: $0) }
            let data = try store.find(dataID: id, password: password)
            completion(.success(data))
        } onFailure: { error in
            completion(.failure(error))
        }

    }

    // TODO: handle data reset
    private func requestPassword(scope: Set<ProtectionClass>, task: @escaping (_ password: String?) throws -> Void, onFailure: @escaping (_ error: Error) -> Void) {
        if
            securityLockEnabled &&
            (lockMethod == .passcode || lockMethod == .passcodeAndUserPresence) &&
                (scope.contains(.sensitive) && AppSettings.passcodeOptions.contains(.useForConfirmation) ||
                 scope.contains(.data) && AppSettings.passcodeOptions.contains(.useForLogin))
        {
            NotificationCenter.default.post(name: .passcodeRequired,
                                            object: self,
                                            userInfo: ["accessTask": task, "onFailure": onFailure])
        } else {
            do {
                try task(nil)
            } catch {
                onFailure(error)
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
}

// SecCenter -> find -> receive pass -> try store.find() -> completed
// SecCent -> find -> receive pass -> try store.find() -> error -> try store.find() ->
