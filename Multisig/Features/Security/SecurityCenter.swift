//
//  SecurityCenter.swift
//  Multisig
//
//  Created by Mouaz on 1/4/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import LocalAuthentication

class SecurityCenter {

    static let shared = SecurityCenter()

    private let sensitiveStore: ProtectedKeyStore
    private let dataStore: ProtectedKeyStore

    private static let version: Int32 = 1
    
    private var isRequirePasscodeEnabled: Bool {
        // TODO: Get settings
        true
    }

    init(sensitiveStore: ProtectedKeyStore, dataStore: ProtectedKeyStore) {
        self.sensitiveStore = sensitiveStore
        self.dataStore = dataStore
    }

    private convenience init() {
        self.init(sensitiveStore: ProtectedKeyStore(protectionClass: .sensitive, KeychainItemStore()), dataStore: ProtectedKeyStore(protectionClass: .data, KeychainItemStore()))
    }

    static func migrateIfNeeded() {
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

    var isEnabled: Bool {
        get {
            SecuritySettings.current().isEnabled
        }
        set {
            let s = SecuritySettings.current()
            s.isEnabled = newValue
            s.save()
        }
    }

    var lockMethod: LockMethod {
        get {
            SecuritySettings.current().lockMethod
        }
        set {
            let s = SecuritySettings.current()
            s.lockMethod = newValue
            s.save()
        }
    }

    var requiresForOpenApp: Bool {
        get {
            SecuritySettings.current().requiresForOpenApp
        }
        set {
            let s = SecuritySettings.current()
            s.requiresForOpenApp = newValue
            s.save()
        }
    }

    var requiresForUsingKeys: Bool {
        get {
            SecuritySettings.current().requiresForUsingKeys
        }
        set {
            let s = SecuritySettings.current()
            s.requiresForUsingKeys = newValue
            s.save()
        }
    }

    func enable(plaintextPasscode: String) {
        let s = SecuritySettings.current()
        s.isEnabled = true
        s.requiresForOpenApp = true
        s.requiresForUsingKeys = true
        s.save()

        // TODO: store derived passcode

        AppSettings.passcodeWasSetAtLeastOnce = true
        NotificationCenter.default.post(name: .passcodeCreated, object: nil)
    }

    func disable() {
        isEnabled = false
        Tracker.trackEvent(.userPasscodeDisabled)
        Tracker.setPasscodeIsSet(to: false)
        NotificationCenter.default.post(name: .passcodeDeleted, object: nil)
    }

    var biometryType: LABiometryType {
        let biometry = Biometry()
        return (try? biometry.type()) ?? .none
    }

    var isBiometrySupported: Bool {
        let biometry = Biometry()
        do {
            let result = try biometry.isSupported()
            return result
        } catch {
            // ignore error
            LogService.shared.debug("Failed to get biometry: \(error)")
            return false
        }
    }

    func activateBiometry(completion: @escaping (Result<Void, Error>) -> Void) {
        let biometry = Biometry()

        biometry.showsFallbackButton = false

        let onFailure = { (e: Error) in
            let error = GSError.BiometryActivationError(underlyingError: e)
            App.shared.snackbar.show(error: error)
            completion(.failure(error))
        }

        do {
            _ = try biometry.canEvaluate(policy: .deviceOwnerAuthenticationWithBiometrics)
        } catch {
            onFailure(error)
            return
        }

        biometry.evaluate(policy: .deviceOwnerAuthenticationWithBiometrics, reason: "Enable login with biometrics") { [unowned self] result in

            switch result {
            case .success:
                self.lockMethod = .userPresence
                NotificationCenter.default.post(name: .biometricsActivated, object: nil)
                completion(result)

            case .failure(let error):
                onFailure(error)
            }

        }
    }

    func deactivateBiometry() {
        lockMethod = .passcode
        App.shared.snackbar.show(message: "Biometrics disabled.")
    }

    func `import`(id: DataID, ethPrivateKey: EthPrivateKey, completion: @escaping (Result<Bool?, Error>) -> ()) {
        perfomSecuredAccess { [unowned self] result in
            switch result {
            case .success:
                do {
                    try sensitiveStore.import(id: id, ethPrivateKey: ethPrivateKey)
                    completion(.success(true))
                } catch let error {
                    completion(.failure(GSError.KeychainError(reason: error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func remove(address: Address, completion: @escaping (Result<Bool?, Error>) -> ()) {
        perfomSecuredAccess { [unowned self] result in
            switch result {
            case .success:
                do {
                    try sensitiveStore.delete(address: address)
                    completion(.success(true))
                } catch let error {
                    completion(.failure(GSError.KeychainError(reason: error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func find(dataID: DataID, completion: @escaping (Result<EthPrivateKey?, Error>) -> ()) {
        perfomSecuredAccess { [unowned self] result in
            switch result {
            case .success(let passcode):
                do {
                    let key = try sensitiveStore.find(dataID: dataID, password: passcode)
                    completion(.success(key))
                } catch let error {
                    completion(.failure(GSError.KeychainError(reason: error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func perfomSecuredAccess(completion: @escaping (Result<String?, Error>) -> ()) {
        guard isRequirePasscodeEnabled else {
            completion(.success(nil))
            return
        }

        let getPasscodeCompletion: (Bool, Bool, String?) -> () = { success, reset, passcode in
            if success, let passcode = passcode {
                completion(.success(passcode))
            } else {
                completion(.failure(GSError.RequiredPasscode()))
            }
        }

        NotificationCenter.default.post(name: .passcodeRequired,
                                        object: self,
                                        userInfo: ["completion": getPasscodeCompletion])
    }
}

