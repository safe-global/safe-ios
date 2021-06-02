//
//  PrivateKey.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 03.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3
import libsecp256k1

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
        // pre-compute context first time it is used
        // because otherwise every time PrivateKey is created, the context gets re-created
        // and this slows down the app (~1.5 extra seconds when generating keys)
        if Self.context == nil {
            Self.context = try Self.createContext()
        }

        // For backward compatibility before generating key on mobile feature
        if let pkData = try? JSONDecoder().decode(PrivateKey.PKData.self, from: data) {
            // performance optimization: passing self-managed context
            _store = try EthereumPrivateKey(privateKey: pkData.key.makeBytes(), ctx: Self.context)
            mnemonic = pkData.mnemonic
        } else {
            _store = try EthereumPrivateKey(privateKey: data.makeBytes(), ctx: Self.context)
        }
        if let value = id {
            self.id = value
        } else {
            self.id = Self.identifier(Address(_store.address))
        }
    }

    // performance optimization: creating private key many times is expensive w/o self-managed context
    // because of the context preparations
    //
    // Below are docs from the Web3 library:
    //    * - parameter ctx: An optional self managed context. If you have specific requirements and
    //    *                  your app performs not as fast as you want it to, you can manage the
    //    *                  `secp256k1_context` yourself with the public methods
    //    *                  `secp256k1_default_ctx_create` and `secp256k1_default_ctx_destroy`.
    //    *                  If you do this, we will not be able to free memory automatically and you
    //    *                  __have__ to destroy the context yourself once your app is closed or
    //    *                  you are sure it will not be used any longer. Only use this optional
    //    *                  context management if you know exactly what you are doing and you really
    //    *                  need it.
    private static func createContext() throws -> OpaquePointer {
        try secp256k1_default_ctx_create(errorThrowable: EthereumPrivateKey.Error.internalError)
    }

    /** Opaque data structure that holds context information (precomputed tables etc.).
     *
     *  The purpose of context structures is to cache large precomputed data tables
     *  that are expensive to construct, and also to maintain the randomization data
     *  for blinding.
     *
     *  Do not create a new context object for each operation, as construction is
     *  far slower than all other API calls (~100 times slower than an ECDSA
     *  verification).
     *
     *  A constructed context can safely be used from multiple threads
     *  simultaneously, but API calls that take a non-const pointer to a context
     *  need exclusive access to it. In particular this is the case for
     *  secp256k1_context_destroy, secp256k1_context_preallocated_destroy,
     *  and secp256k1_context_randomize.
     *
     *  Regarding randomization, either do it once at creation time (in which case
     *  you do not need any locking for the other calls), or use a read-write lock.
     */
    private static var context: OpaquePointer?

    // cleaning up memory should be called when app is closed.
    static func cleanup() {
        if let ctx = context {
            secp256k1_default_ctx_destroy(ctx: ctx)
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
