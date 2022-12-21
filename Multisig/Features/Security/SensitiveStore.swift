//
//  SensitiveStore.swift
//  Multisig
//
//  Created by Dirk Jäckel on 30.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class SensitiveStore: EncryptedStore {
    private let store: KeychainItemStore

    static let sensitivePublicKeyTag = "global.safe.sensitivePublicKeyTag"
    static let sensitivePublicKEKTag = "global.safe.sensitivePublicKEKTag"
    static let sensitivePrivateKEKTag = "global.safe.sensitivePrivateKEKTag"
    static let sensitiveEncryptedPrivateKeyTag = "global.safe.sensitive.private.key.as.encrypted.data"
    static let derivedPasswordTag = "global.safe.password.as.data"

    init(_ store: KeychainItemStore) {
        self.store = store
    }

    func initializeKeyStore() throws {
        try initialize()
    }

    func isInitialized() -> Bool {
        do {
            return try store.find(.ecPubKey(tag: SensitiveStore.sensitivePublicKeyTag)) != nil
        } catch {
            LogService.shared.error("SensitiveStore is not initialized", error: error)
            return false
        }
    }

    func `import`(id: DataID, ethPrivateKey: EthPrivateKey) throws {
        //1. create key from Data
        let privateKey = try PrivateKey(data: ethPrivateKey)

        // 2. find public sensitive key
        let pubKey = try store.find(.ecPubKey()) as! SecKey

        // 3. encrypt private key with public sensitive key
        var error: Unmanaged<CFError>?

        let encryptedSigningKey = try ethPrivateKey.encrypt(publicKey: pubKey)

        // 4. store encrypted blob in the keychain
        let address = privateKey.address
        try store.create(KeychainItem.generic(id: id.id, service: id.protectionClass.service(), data: encryptedSigningKey))
    }

    func delete(address: Address) throws {
        try store.delete(KeychainItem.generic(id: address.checksummed, service: ProtectionClass.sensitive.service()))
    }

    func find(dataID: DataID, password: String?) throws -> EthPrivateKey? {
        // Get encrypted signing key
        guard let encryptedSigningKey = try store.find(KeychainItem.generic(id: dataID.id, service: dataID.protectionClass.service())) as? Data else {
            return nil
        }
        // If no password given retrieve the password from store
        let storedPassword = try store.find(KeychainItem.generic(id: SensitiveStore.derivedPasswordTag, service: ProtectionClass.sensitive.service())) as! Data?
        let password = password != nil ? password?.data(using: .utf8) : storedPassword

        // Get access to secure enclave key
        let sensitiveKEK = try store.find(KeychainItem.enclaveKey(password: password)) as! SecKey

        // Get access to encrypted sensitive key
        let encryptedSensitiveKey = try store.find(KeychainItem.generic(id: SensitiveStore.sensitiveEncryptedPrivateKeyTag, service: ProtectionClass.sensitive.service())) as? Data
        // Decrypt sensitiveKey
        let decryptedSensitiveKeyData = try encryptedSensitiveKey?.decrypt(privateKey: sensitiveKEK)

        // Restore sensitive key from Data
        var error: Unmanaged<CFError>?
        guard let decryptedSensitiveKey: SecKey = SecKeyCreateWithData(decryptedSensitiveKeyData! as CFData, try KeychainItem.ecKeyPair.creationAttributes(), &error) else {
            // will fail here if password was wrong
            throw error!.takeRetainedValue() as Error
        }
        // Decrypt signer key with sensitive key
        return try encryptedSigningKey.decrypt(privateKey: decryptedSensitiveKey)
    }

    func changePassword(from oldPassword: String, to newPassword: String) {

    }

    func changeSettings() {

    }

    func initialize() throws {
        // 1. create password
        let passwordData = createRandomBytes(32)
        // store password
        let passItem = KeychainItem.generic(
                id: SensitiveStore.derivedPasswordTag,
                service: ProtectionClass.sensitive.service(),
                data: passwordData
        )
        try store.create(passItem)

        // 2. create kek
        // kek security attributes are
        // based on the user's security settings
        // and on the defaults
        // that is application/module-specific
        let kekItem = KeychainItem.enclaveKey(
                tag: SensitiveStore.sensitivePrivateKEKTag,
                password: passwordData,
                access: [.applicationPassword]
        )
        let keyEncryptionKey: SecKey = try store.create(kekItem) as! SecKey

        // 3. create key pair
        let privateKeyItem = KeychainItem.ecKeyPair // is it a pair though? also, why no tag? because it is not stored directly.
        let sensitiveKey: SecKey = try store.create(privateKeyItem) as! SecKey

        let encryptedPK = try Data(secKey: sensitiveKey).encrypt(publicKey: keyEncryptionKey.publicKey())

        // store key pair
        // store encrypted private key
        let encryptedPrivateKeyItem = KeychainItem.generic(
                id: SensitiveStore.sensitiveEncryptedPrivateKeyTag,
                service: ProtectionClass.sensitive.service(),
                data: encryptedPK)
        try store.create(encryptedPrivateKeyItem)

        // store public key
        let pubKeyItem = KeychainItem.ecPubKey(
                tag: SensitiveStore.sensitivePublicKeyTag,
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

    func encrypt(publicKey: SecKey?) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let encryptedSensitiveKey = SecKeyCreateEncryptedData(publicKey!, .eciesEncryptionStandardX963SHA256AESGCM, self as CFData, &error) as? Data else {
            throw error!.takeRetainedValue() as Error
        }
        return encryptedSensitiveKey
    }

    func decrypt(privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let decryptedSensitiveKeyData = SecKeyCreateDecryptedData(privateKey, .eciesEncryptionStandardX963SHA256AESGCM, self as CFData, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        return decryptedSensitiveKeyData as Data
    }
}

extension SecKey {
    func publicKey() -> SecKey {
        // extract public key using SecKeyCopyPublicKey
        SecKeyCopyPublicKey(self)!
    }
}
