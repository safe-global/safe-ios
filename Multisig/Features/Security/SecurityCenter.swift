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

    static func setUp() {
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
        }
    }

    func changeSecuritySettings(passcode: String?, lockMethod: LockMethod? = nil,  completion: @escaping (Error?) -> Void) {
        let password: String? = passcode == nil ? nil : derivedKey(from: passcode!)
        let newLockMethod = lockMethod == nil ? self.lockMethod : lockMethod!
        perfomSecuredAccess { [unowned self] result in
            let SUCCESS: Error? = nil
            do {
                let old = try result.get()
                try sensitiveStore.changePassword(from: old, to: password, useBiometry: newLockMethod != .passcode)
                try dataStore.changePassword(from: old, to: password, useBiometry: newLockMethod != .passcode)
                completion(SUCCESS)
            } catch {
                completion(error)
            }
        }
    }

    // import data potentially overriding existing value
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

    func remove(dataID: DataID, completion: @escaping (Result<Bool?, Error>) -> ()) {
        perfomSecuredAccess { [unowned self] result in
            switch result {
            case .success:
                do {
                    try sensitiveStore.delete(id: dataID)
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
        guard securityLockEnabled else {
            completion(.success(nil))
            return
        }

        let getPasscodeCompletion: (_ success: Bool, _ reset: Bool, _ passcode: String?) -> () = { success, reset, passcode in
            // TODO: handle data reset
            // TODO: handle incorrect passcode
            if success {
                completion(.success(passcode.map { App.shared.securityCenter.derivedKey(from: $0) }))
            } else {
                completion(.failure(GSError.RequiredPasscode()))
            }
        }

        NotificationCenter.default.post(name: .passcodeRequired,
                                        object: self,
                                        userInfo: ["completion": getPasscodeCompletion])
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
