//
//  SensitiveStore.swift
//  Multisig
//
//  Created by Dirk Jäckel on 30.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class ProtectedKeyStore: EncryptedStore {

    private let protectionClass: ProtectionClass
    private let store: KeychainItemStore

    static let publicKeyTag = "global.safe.publicKeyTag"
    static let publicKEKTag = "global.safe.publicKEKTag"
    static let privateKEKTag = "global.safe.privateKEKTag"
    static let encryptedPrivateKeyTag = "global.safe.private.key.as.encrypted.data"
    static let derivedPasswordTag = "global.safe.password.as.data"


    init(protectionClass: ProtectionClass, _ store: KeychainItemStore) {
        self.store = store
        self.protectionClass = protectionClass
    }

    func initializeKeyStore() throws {
        try initialize()
    }

    func isInitialized() -> Bool {
        do {
            return try store.find(.ecPubKey(tag: ProtectedKeyStore.publicKeyTag, service: protectionClass.service())) != nil
        } catch {
            LogService.shared.error("SensitiveStore is not initialized", error: error)
            return false
        }
    }

    func `import`(id: DataID, ethPrivateKey: EthPrivateKey) throws {
        //1. create key from Data
        let privateKey = try PrivateKey(data: ethPrivateKey)

        // 2. find public sensitive key
        let pubKey = try store.find(.ecPubKey(tag: ProtectedKeyStore.publicKeyTag, service: protectionClass.service())) as! SecKey

        // 3. encrypt private key with public sensitive key
        let encryptedSigningKey = try ethPrivateKey.encrypt(publicKey: pubKey)

        // 4. store encrypted blob in the keychain
        let address = privateKey.address
        try store.create(KeychainItem.generic(account: id.id, service: protectionClass.service(), data: encryptedSigningKey))
    }

    func delete(address: Address) throws {
        try store.delete(KeychainItem.generic(account: address.checksummed, service: protectionClass.service()))
    }

    func find(dataID: DataID, password: String?) throws -> EthPrivateKey? {
        // Get encrypted signing key
        guard let encryptedSigningKey = try store.find(KeychainItem.generic(account: dataID.id, service: protectionClass.service())) as? Data else {
            return nil
        }
        // If no password given retrieve the password from store
        let password = password != nil ? password?.data(using: .utf8) : try store.find(KeychainItem.generic(account: ProtectedKeyStore.derivedPasswordTag, service: protectionClass.service())) as! Data?

        // Get access to secure enclave key
        let sensitiveKEK = try store.find(KeychainItem.enclaveKey(tag: ProtectedKeyStore.privateKEKTag, service: protectionClass.service() ,password: password)) as! SecKey

        // Get access to encrypted sensitive key
        let encryptedSensitiveKey = try store.find(KeychainItem.generic(account: ProtectedKeyStore.encryptedPrivateKeyTag, service: protectionClass.service())) as? Data
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

    // Options:
    //          userCreatedAppPasscode -> true/false
    //                     -> oldPassword == nil  and/or newPassword == nil
    //                        oldPassword == nil -> use stored password to access current KEK
    //                        newPassword == nil -> use stored password to access KEK
    //          useBiometry -> true/false
    func changePassword(from oldPassword: String?, to newPassword: String?, useBiometry: Bool = false) throws {
        // find sensitive key
        let encryptedSensitiveKey = try store.find(KeychainItem.generic(account: ProtectedKeyStore.encryptedPrivateKeyTag, service: protectionClass.service())) as? Data
        // if no old password given, retrieve stored password
        let passwordData = oldPassword != nil ? oldPassword?.data(using: .utf8) : try store.find(KeychainItem.generic(account: ProtectedKeyStore.derivedPasswordTag, service: protectionClass.service())) as! Data?
        // find KEK
        let sensitiveKEK = try store.find(KeychainItem.enclaveKey(tag: ProtectedKeyStore.privateKEKTag, service: protectionClass.service(), password: passwordData)) as! SecKey

        // decrypt sensitive key
        let decryptedSensitiveKeyData = try encryptedSensitiveKey?.decrypt(privateKey: sensitiveKEK)
        // Restore sensitive key from Data
        var error: Unmanaged<CFError>?

        let decryptedSensitiveKey: SecKey? = SecKeyCreateWithData(decryptedSensitiveKeyData! as CFData, try KeychainItem.ecKeyPair.creationAttributes(), &error)
        guard decryptedSensitiveKey != nil else {
            // will fail here if password was wrong
            throw error!.takeRetainedValue() as Error
        }

        // if no newPassword given, create a random password an store it
        var newPasswordData = newPassword?.data(using: .utf8)
        if newPasswordData == nil {
            let passwordData = createRandomBytes(32)
            let passItem = KeychainItem.generic(
                    account: ProtectedKeyStore.derivedPasswordTag,
                    service: protectionClass.service(),
                    data: passwordData
            )
            try store.create(passItem)
            newPasswordData = passwordData
        }

        var accessFlags: SecAccessControlCreateFlags = [.applicationPassword]
        if useBiometry {
            accessFlags = [.applicationPassword, .userPresence]
        }

        // create new KEK with new app password
        let kekItem = KeychainItem.enclaveKey(
                tag: ProtectedKeyStore.privateKEKTag,
                service: protectionClass.service(),
                password: newPasswordData,
                access: accessFlags
        )

        let keyEncryptionKey: SecKey = try store.create(kekItem) as! SecKey

        // create key pair
        let privateKeyItem = KeychainItem.ecKeyPair
        let sensitiveKey: SecKey = try store.create(privateKeyItem) as! SecKey

        let encryptedPK = try Data(secKey: sensitiveKey).encrypt(publicKey: keyEncryptionKey.publicKey())

        // store key pair
        // store sensitive key
        // store encrypted private key
        let encryptedPrivateKeyItem = KeychainItem.generic(
                account: ProtectedKeyStore.encryptedPrivateKeyTag,
                service: protectionClass.service(),
                data: encryptedPK)
        try store.create(encryptedPrivateKeyItem)

        // store public key
        let pubKeyItem = KeychainItem.ecPubKey(
                tag: ProtectedKeyStore.publicKeyTag,
                service: protectionClass.service(),
                publicKey: sensitiveKey.publicKey()
        )
        try store.create(pubKeyItem)
    }

    func initialize() throws {
        // 1. create password
        let passwordData = createRandomBytes(32)
        // store password
        let passItem = KeychainItem.generic(
                account: ProtectedKeyStore.derivedPasswordTag,
                service: protectionClass.service(),
                data: passwordData
        )
        try store.create(passItem)

        // 2. create kek
        // kek security attributes are
        // based on the user's security settings
        // and on the defaults
        // that is application/module-specific
        let kekItem = KeychainItem.enclaveKey(
                tag: ProtectedKeyStore.privateKEKTag,
                service: protectionClass.service(),
                password: passwordData,
                access: [.applicationPassword]
        )
        let keyEncryptionKey: SecKey = try store.create(kekItem) as! SecKey

        // 3. create key pair
        let privateKeyItem = KeychainItem.ecKeyPair
        let sensitiveKey: SecKey = try store.create(privateKeyItem) as! SecKey

        let encryptedPK = try Data(secKey: sensitiveKey).encrypt(publicKey: keyEncryptionKey.publicKey())

        // store key pair
        // store encrypted private key
        let encryptedPrivateKeyItem = KeychainItem.generic(
                account: ProtectedKeyStore.encryptedPrivateKeyTag,
                service: protectionClass.service(),
                data: encryptedPK)
        try store.create(encryptedPrivateKeyItem)

        // store public key
        let pubKeyItem = KeychainItem.ecPubKey(
                tag: ProtectedKeyStore.publicKeyTag,
                service: protectionClass.service(),
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

    func deleteAllKeys() throws {
        try! store.delete(.generic(account: ProtectedKeyStore.derivedPasswordTag, service: protectionClass.service()))
        try! store.delete(.generic(account: ProtectedKeyStore.encryptedPrivateKeyTag, service: protectionClass.service()))
        try! store.delete(.ecPubKey(tag: ProtectedKeyStore.publicKeyTag, service: protectionClass.service()))
        try! store.delete(.enclaveKey(tag: ProtectedKeyStore.privateKEKTag, service: protectionClass.service()))
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
