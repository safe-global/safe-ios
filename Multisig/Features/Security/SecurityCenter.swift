//
//  SecurityCenter.swift
//  Multisig
//
//  Created by Mouaz on 1/4/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

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

    private func performSecuredAccess(completion: @escaping (Result<String?, Error>) -> ()) {
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
