//
//  PrivateKey.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 03.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import SafeWeb3

struct PrivateKey {
    var id: KeyID
    var mnemonic: String?
    private(set) var _store: EthereumPrivateKey

    typealias KeyID = String

    var address: Address {
        Address(_store.address)
    }

    struct PKData: Codable {
        let key: Data
        let mnemonic: String?
    }

    var keyData: Data {
        Data(_store.rawPrivateKey)
    }

    var keychainData: Data {
        let pkData = PKData(key: Data(_store.rawPrivateKey), mnemonic: mnemonic)
        return try! JSONEncoder().encode(pkData)
    }
}

extension PrivateKey {
    init(mnemonic: String, pathIndex: Int, id: KeyID? = nil) throws {
        guard let seed = BIP39.seedFromMmemonics(mnemonic),
              let seedNode = HDNode(seed: seed),
              let prefixNode = seedNode.derive(
                path: HDNode.defaultPathMetamaskPrefix,
                derivePrivateKey: true),
              let keyNode = prefixNode.derive(index: UInt32(pathIndex), derivePrivateKey: true),
              let keyData = keyNode.privateKey
        else {
            throw GSError.ThirdPartyError(reason: "Invalid mnemonic or key index")
        }
        _store = try EthereumPrivateKey(keyData)
        self.mnemonic = mnemonic
        if let value = id {
            self.id = value
        } else {
            self.id = Self.identifier(Address(_store.address))
        }
    }

    init(data: Data, id: KeyID? = nil) throws {
        // For backward compatibility before generating key on mobile feature
        if let pkData = try? JSONDecoder().decode(PrivateKey.PKData.self, from: data) {
            _store = try EthereumPrivateKey(pkData.key)
            mnemonic = pkData.mnemonic
        } else {
            _store = try EthereumPrivateKey(data)
        }
        if let value = id {
            self.id = value
        } else {
            self.id = Self.identifier(Address(_store.address))
        }
    }

    static func identifier(_ address: Address) -> KeyID {
        KeychainKey.ownerPrivateKey + address.checksummed
    }

    //@Deprecated: legacy code
    static func key(address: Address) throws -> PrivateKey? {
        try key(id: identifier(address))
    }

    //@Deprecated: legacy code
    //TODO: extract legacy code
    static func key(id: KeyID) throws -> PrivateKey? {
        do {
            let pkDataOrNil = try App.shared.keychainService.data(forKey: id)
            guard let pkData = pkDataOrNil else { return nil }
            return try PrivateKey(data: pkData, id: id)
        } catch let error as GSError.KeychainError {
            throw  error
        } catch {
            throw GSError.ThirdPartyError(reason: error.localizedDescription)
        }

    }

    static func key(address: Address, protectionClass: ProtectionClass = .sensitive, completion: @escaping (Result<PrivateKey?, Error>) -> ()) {
        try key(id: identifier(address), protectionClass: protectionClass, completion: completion)
    }

    //TODO: move access through security center to a separate function (preferrably outside of PrivateKey)
    static func key(id: KeyID, protectionClass: ProtectionClass = .sensitive, completion: @escaping (Result<PrivateKey?, Error>) -> ()) {
        if AppConfiguration.FeatureToggles.securityCenter {
            App.shared.securityCenter.find(dataID: DataID(id: id), protectionClass: protectionClass) { result in
                do {
                    let pkDataOrNil = try result.get()
                    guard let pkData = pkDataOrNil else {
                        completion(.success(nil))
                        return
                    }
                    let privateKey = try PrivateKey(data: pkData, id: id)
                    completion(.success(privateKey))
                } catch let error as GSError.KeychainError {
                    completion(.failure(error))
                } catch let error as GSError.CancelledByUser {
                    completion(.failure(error))
                } catch {
                    completion(.failure(GSError.ThirdPartyError(reason: error.localizedDescription)))
                }
            }
        } else {
            do {
                let privateKey = try key(id: id)
                completion(.success(privateKey))
            } catch let error as GSError.KeychainError {
                completion(.failure(error))
            } catch {
                completion(.failure(GSError.ThirdPartyError(reason: error.localizedDescription)))
            }
        }
    }

    //@Deprecated: legacy code
    //TODO: extract legacy code
    static func remove(id: KeyID,
                       protectionClass: ProtectionClass = .sensitive,
                       authenticate: Bool = true,
                       completion: ((Result<Bool, Error>) -> ())? = nil) {
        if AppConfiguration.FeatureToggles.securityCenter {
            //TODO: rewrite as App.securityCenter
            //TODO: make invocation async
            App.shared.securityCenter.remove(dataID: DataID(id: id), protectionClass: protectionClass, authenticate: authenticate) { result in
                completion?(result)
            }
        } else {
            do {
                try App.shared.keychainService.removeData(forKey: id)
                completion?(.success(true))
            } catch {
                completion?(.failure(GSError.KeychainError(reason: error.localizedDescription)))
            }
        }
    }

    static func deleteAll() throws {
        do {
            let keys = try App.shared.keychainService.allKeys()
                .filter { $0.starts(with: KeychainKey.ownerPrivateKey) }
            for key in keys {
                try App.shared.keychainService.removeData(forKey: key)
            }
        } catch {
            throw GSError.KeychainError(reason: error.localizedDescription)
        }
    }

    //@Deprecated: legacy code
    //TODO: extract legacy code; move access through security center to a separate function (preferrably outside of PrivateKey)
    func save(protectionClass: ProtectionClass = .sensitive) throws {
        if AppConfiguration.FeatureToggles.securityCenter {
            //TODO: rewrite as App.securityCenter
            //TODO: make invocation async
            App.shared.securityCenter.import(id: DataID(id: id), data: keychainData, protectionClass: protectionClass) { result in
                try! result.get()
            }
        } else {
            do {
                try App.shared.keychainService.removeData(forKey: id)
                try App.shared.keychainService.save(data: keychainData, forKey: id)
            } catch {
                throw GSError.KeychainError(reason: error.localizedDescription)
            }
        }
    }

    func remove(protectionClass: ProtectionClass = .sensitive,
                completion: ((Result<Bool, Error>) -> ())? = nil) {
        Self.remove(id: id, protectionClass: protectionClass, completion: completion)
    }

    func sign(hash: Data) throws -> Signature {
        let result = try _store.sign(hash: Array(hash))
        return Signature(v: result.v + 27, r: Data(result.r), s: Data(result.s), signer: address)
    }
}

/// Represents Ethereum EOA signature
struct Signature {
    var v: UInt
    var r: Data
    var s: Data

    var signer: Address

    var hexadecimal: String {
        r.toHexStringWithPrefix() + s.toHexString() + String(v, radix: 16)
    }
}


extension PrivateKey {
    static func v1SingleKey() throws -> PrivateKey? {
        try self.key(id: PrivateKey.v1KeyID)
    }

    private static let v1KeyID: KeyID = KeychainKey.ownerPrivateKey
}
