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
    private var _store: EthereumPrivateKey

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

    static func remove(id: KeyID) throws {
        do {
            try App.shared.keychainService.removeData(forKey: id)
        } catch {
            throw GSError.KeychainError(reason: error.localizedDescription)
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

    func save() throws {
        do {
            try App.shared.keychainService.removeData(forKey: id)
            try App.shared.keychainService.save(data: keychainData, forKey: id)
        } catch {
            throw GSError.KeychainError(reason: error.localizedDescription)
        }
    }

    func remove() throws {
        try Self.remove(id: id)
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
