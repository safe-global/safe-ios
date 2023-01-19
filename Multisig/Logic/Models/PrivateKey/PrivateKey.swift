//
//  PrivateKey.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 03.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3

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

    //TODO: move access through security center to a separate function (preferrably outside of PrivateKey)
    static func key(id: KeyID, completion: @escaping (Result<PrivateKey?, Error>) -> ()) {
        App.shared.securityCenter.find(dataID: DataID(id: id)) { result in
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
            } catch {
                completion(.failure(GSError.ThirdPartyError(reason: error.localizedDescription)))
            }
        }
    }

    //@Deprecated: legacy code
    //TODO: extract legacy code
    static func remove(id: KeyID, address: Address) throws {
        if AppConfiguration.FeatureToggles.securityCenter {
            //TODO: rewrite as App.securityCenter
            //TODO: make invocation async
            App.shared.securityCenter.remove(address: address) { result in
                try! result.get()
            }
        } else {
            do {
                try App.shared.keychainService.removeData(forKey: id)
            } catch {
                throw GSError.KeychainError(reason: error.localizedDescription)
            }
        }
    }

    static func remove(address: Address, completion: @escaping (Result<Bool?, Error>) -> ()) {
        App.shared.securityCenter.remove(address: address, completion: completion)
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
    func save() throws {
        if AppConfiguration.FeatureToggles.securityCenter {
            //TODO: rewrite as App.securityCenter
            //TODO: make invocation async
            App.shared.securityCenter.import(id: DataID(id: id), ethPrivateKey: keychainData) { result in
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

    func remove() throws {
        try Self.remove(id: id, address: address)
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
