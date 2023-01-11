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

    private let sensitiveStore = SensitiveStore.shared
    private var isRequirePasscodeEnabled: Bool {
        // TODO: Get settings
        true
    }

    private init() { }

    func `import`(id: DataID, ethPrivateKey: EthPrivateKey, completion: @escaping (Result<Bool?, Error>) -> ()) {
        perfomSecuredAccess { [unowned self] result in
            switch result {
            case .success(let _):
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

    func remove(id: DataID, completion: @escaping (Result<Bool?, Error>) -> ()) {
        perfomSecuredAccess { [unowned self] result in
            switch result {
            case .success(let _):
                do {
                    try sensitiveStore.delete(id: id)
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
