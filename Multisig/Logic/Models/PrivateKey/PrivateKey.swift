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
    private var _store: EthereumPrivateKey

    typealias KeyID = String

    var address: Address {
        Address(_store.address)
    }

    var data: Data {
        try! Data(_store.address.makeBytes())
    }
}

extension PrivateKey {

    init(mnemonic: [String], pathIndex: Int) throws {
        guard
            let seed = BIP39.seedFromMmemonics(mnemonic.joined(separator: " ")),
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
        id = ""
        id = KeychainKey.ownerPrivateKey + address.checksummed
    }

    init(data: Data) throws {
        _store = try EthereumPrivateKey(data)
        id = ""
        id = KeychainKey.ownerPrivateKey + address.checksummed
    }

    static func id(_ address: Address) -> KeyID {
        KeychainKey.ownerPrivateKey + address.checksummed
    }

    static func key(address: Address) throws -> PrivateKey? {
        try key(id: id(address))
    }

    static func key(id: KeyID) throws -> PrivateKey? {
        do {
            let pkDataOrNil = try App.shared.keychainService.data(forKey: id)
            guard let pkData = pkDataOrNil else { return nil }
            return try PrivateKey(data: pkData)
        } catch {
            throw GSError.KeychainError(reason: error.localizedDescription)
        }
    }

    static func remove(id: KeyID) throws {
        do {
            try App.shared.keychainService.removeData(forKey: id)
        } catch {
            throw GSError.KeychainError(reason: error.localizedDescription)
        }
    }

    func save() throws {
        do {
            try App.shared.keychainService.removeData(forKey: id)
            try App.shared.keychainService.save(data: data, forKey: id)
        } catch {
            throw GSError.KeychainError(reason: error.localizedDescription)
        }
    }

    func remove() throws {
        try Self.remove(id: id)
    }

    func sign(hash: Data) throws -> (v: UInt, r: Data, s: Data) {
        let result = try _store.sign(hash: Array(hash))
        return (result.v, Data(result.r), Data(result.s))
    }
}


extension PrivateKey {

    @available(*, deprecated, message: "Will be removed after refactoring")
    init(legacy data: Data) throws {
        _store = try EthereumPrivateKey(data)
        id = ""
        id = KeychainKey.ownerPrivateKey
    }

    @available(*, deprecated, message: "Will be removed after refactoring")
    static func legacySingleKey() throws -> PrivateKey? {
        try key(id: Self.legacyKeyID)
    }

    @available(*, deprecated, message: "Will be removed after refactoring")
    static let legacyKeyID: KeyID = KeychainKey.ownerPrivateKey
}
