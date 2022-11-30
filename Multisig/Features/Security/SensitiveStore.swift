//
//  SensitiveStore.swift
//  Multisig
//
//  Created by Dirk Jäckel on 30.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class SensitiveStore: EncryptedStore {
    func isInitialized() -> Bool {
        false
    }

    func initializeKeyStore() throws {
        try initialize()
    }

    func `import`(id: DataID, ethPrivateKey: EthPrivateKey) throws {

    }

    func delete(address: Address) {

    }

    func find(dataID: DataID, password: String?) throws -> EthPrivateKey? {
        return nil
    }

    func changePassword(from oldPassword: String, to newPassword: String) {

    }

    func changeSettings() {

    }

    // private KEK ID (in secure enclave)
    // private key ID (encrypted by private KEK)
    // public key ID (unencrypted)
    // password ID
    // service ID

    private let store: KeychainItemStore

    private let passwordID = "passwordID"
    private let serviceID = "serviceID"
    private let privateKEKID = "privateKEKID"
    private let privateKeyID = "privateKeyID"
    private let publicKeyID = "publicKeyID"

    init(_ store: KeychainItemStore) {
        self.store = store
    }

    func initialize() throws {
        // 1. create password
        let passwordData = createRandomBytes(32)

        // store password
        let passItem = KeychainItem.generic(
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
        let kekItem = KeychainItem.enclaveKey(
                tag: privateKEKID,
                password: passwordData,
                access: [.applicationPassword, .userPresence])
        let keyEncryptionKey: SecKey = try store.create(kekItem) as! SecKey

        // 3. create key pair
        let privateKeyItem = KeychainItem.ecKeyPair // is it a pair though? also, why no tag? because it is not stored directly.
        let sensitiveKey: SecKey = try store.create(privateKeyItem) as! SecKey

        let encryptedPK = try encrypt(publicKey: keyEncryptionKey.publicKey(), plainText: Data(secKey: sensitiveKey))

        // store key pair
        // store encrypted private key
        let encryptedPrivateKeyItem = KeychainItem.generic(
                id: privateKeyID,
                service: serviceID,
                data: encryptedPK)
        try store.create(encryptedPrivateKeyItem)

        // store public key
        let pubKeyItem = KeychainItem.ecPubKey(
                tag: publicKeyID,
                publicKey: sensitiveKey.publicKey()
        )
        try store.create(pubKeyItem)
    }

    private func createRandomBytes(_ amount: Int) -> Data? {
        var bytes: [UInt8] = .init(repeating: 0, count: amount)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard result == errSecSuccess else {
            return nil
        }
        return Data(bytes)
    }

    private func encrypt(publicKey: SecKey?, plainText: Data) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let encryptedSensitiveKey = SecKeyCreateEncryptedData(publicKey!, .eciesEncryptionStandardX963SHA256AESGCM, plainText as CFData, &error) as? Data else {
            throw error!.takeRetainedValue() as Error
        }
        return encryptedSensitiveKey
    }

    private func decrypt(privateKey: SecKey, encryptedData: Data) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let decryptedSensitiveKeyData = SecKeyCreateDecryptedData(privateKey, .eciesEncryptionStandardX963SHA256AESGCM, encryptedData as CFData, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        return decryptedSensitiveKeyData as Data
    }

}

extension Data {
    init(secKey: SecKey) throws {
        self.init()
        var error: Unmanaged<CFError>?
        guard let sensitiveKeyData = SecKeyCopyExternalRepresentation(secKey, &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }

        self = sensitiveKeyData
    }
}

extension SecKey {
    func publicKey() -> SecKey {
        // extract public key using SecKeyCopyPublicKey
        SecKeyCopyPublicKey(self)!
    }
}
