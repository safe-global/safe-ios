//
//  SensitiveStore.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 29.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class SensitiveStore {
    // private KEK ID (in secure enclave)
    // private key ID (encrypted by private KEK)
    // public key ID (unencrypted)
    // password ID
    // service ID

    private let store : KeychainItemStore

    init(_ store: KeychainItemStore) {
        self.store = store
    }

    func initialize() throws {
        // 1. create password
        let passwordData = try createRandomBytes(32)

        // store password
        let passItem = KeychainStoreItem.generic(
            id: passwordID,
            service: serviceID,
            data: passwordData
        )
        try store.create(passItem)

        // 2. create kek
            // kek security attributes are
            // based on the user's security settings
            // and on the defaults
            // that is application/module-specific
        let kekItem = KeychainStoreItem.enclaveKey(
            tag: privateKEKID,
            password: passwordData,
            access: [.applicationPassword, .userPresence])
        let keyEncryptionKey = try store.create(kekItem)

        // 3. create key pair
        let privateKeyItem = KeychainStoreItem.ecKeyPair // is it a pair though? also, why no tag? because it is not stored directly.
        let privateKey = try store.create(privateKeyItem)

        let encryptedPK = try encrypt(Data(privateKey: privateKey), keyEncryptionKey.publicKey())

        // store key pair
            // store encrypted private key
        let encryptedPrivateKeyItem = KeychainStoreItem.generic(
            id: privateKeyID,
            service: serviceID,
            data: encryptedPK)
        try store.create(encryptedPrivateKeyItem)

            // store public key
        let pubKeyItem = KeychainStoreItem.ecPubKey(
            tag: publicKeyID,
            publicKey: pubKey
        )
        try store.create(pubKeyItem)
    }

}
