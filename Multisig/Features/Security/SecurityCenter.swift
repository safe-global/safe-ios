//
//  SecurityCenter.swift
//  Multisig
//
//  Created by Mouaz on 1/4/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreText

class SecurityCenter {

    static let shared = SecurityCenter()

    private let sensitiveStore: ProtectedKeyStore
    private let dataStore: ProtectedKeyStore

    private static let version: Int32 = 1
    
    private var isRequirePasscodeEnabled: Bool {
        AppSettings.securityLockEnabled
    }

    init(sensitiveStore: ProtectedKeyStore, dataStore: ProtectedKeyStore) {
        self.sensitiveStore = sensitiveStore
        self.dataStore = dataStore
        try! dataStore.import(id: DataID(id: "app.unlock"), ethPrivateKey: Data(ethHex: "da18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c322"))
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
            try! dataStore.import(id: DataID(id: "app.unlock"), ethPrivateKey: Data(ethHex: "da18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c322"))
        }
    }

    func changePasscode(new: String?, useBiometry: Bool, completion: @escaping (Error?) -> Void) {
        //TODO: Check if passcode is nil -> stored within ProtectedKeyStore
        if sensitiveStore.useStoredPassword() && dataStore.useStoredPassword() {
            do {
                try sensitiveStore.changePassword(from: nil, to: new, useBiometry: useBiometry)
                try dataStore.changePassword(from: nil, to: new, useBiometry: useBiometry)
            } catch {
                completion(error)
            }
        } else {
            performSecuredAccess { [unowned self] result in
                let SUCCESS: Error? = nil
                do {
                    let old = try result.get()
                    try sensitiveStore.changePassword(from: old, to: new, useBiometry: useBiometry)
                    try dataStore.changePassword(from: old, to: new, useBiometry: useBiometry)
                    completion(SUCCESS)
                } catch {
                    completion(error)
                }
            }
        }



    }

    // import data potentially overriding existing value
    func `import`(id: DataID, ethPrivateKey: EthPrivateKey, completion: @escaping (Result<Bool?, Error>) -> ()) {
        performSecuredAccess { [unowned self] result in
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
        performSecuredAccess { [unowned self] result in
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
        performSecuredAccess { [unowned self] result in
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

    func isPasscodeCorrect(derivedPasscode: String?) throws -> Bool {
        return try dataStore.find(dataID: DataID(id: "app.unlock"), password: derivedPasscode) != nil
    }

    private func performSecuredAccess(completion: @escaping (Result<String?, Error>) -> ()) {
        guard isRequirePasscodeEnabled else {
            completion(.success("nil"))
            return
        }

        let getPasscodeCompletion: (_ success: Bool, _ reset: Bool, _ passcode: String?) -> () = { success, reset, passcode in
            // TODO: handle data reset
            // TODO: handle incorrect passcode
            if success {
                completion(.success(passcode.map { App.shared.auth.derivedKey(from: $0) }))
            } else {
                completion(.failure(GSError.RequiredPasscode()))
            }
        }

        NotificationCenter.default.post(name: .passcodeRequired,
                                        object: self,
                                        userInfo: ["completion": getPasscodeCompletion])
    }
}
