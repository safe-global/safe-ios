//
//  SensitiveStore.swift
//  Multisig
//
//  Created by Dirk Jäckel on 30.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class ProtectedKeyStore: EncryptedStore {

    let protectionClass: ProtectionClass
    private let store: KeychainItemStore

    static let publicKeyTag = "global.safe.publicKeyTag"
    static let privateKEKTag = "global.safe.privateKEKTag"
    static let encryptedPrivateKeyTag = "global.safe.private.key.as.encrypted.data"
    static let derivedPasswordTag = "global.safe.password.as.data"

    private var sensitiveKey: SecKey? = nil

    var unlocked: Bool {
        return sensitiveKey != nil
    }


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

    func unlock(derivedPassword: String? = nil) throws {

        let rawPassword: Data?
        if let password = derivedPassword {
            rawPassword = password.data(using: .utf8)
        } else {
            let derivedPasswordItem = KeychainItem.generic(account: ProtectedKeyStore.derivedPasswordTag, service: protectionClass.service())
            rawPassword = try store.find(derivedPasswordItem) as! Data?
        }

        // Get access to secure enclave key
        let sensitiveKEK = try store.find(KeychainItem.enclaveKey(tag: ProtectedKeyStore.privateKEKTag, service: protectionClass.service(), password: rawPassword)) as! SecKey

        // Get access to encrypted sensitive key
        let encryptedSensitiveKey = try store.find(KeychainItem.generic(account: ProtectedKeyStore.encryptedPrivateKeyTag, service: protectionClass.service())) as? Data
        let decryptedSensitiveKeyData = try encryptedSensitiveKey?.decrypt(privateKey: sensitiveKEK)
        var error: Unmanaged<CFError>?
        guard let decryptedSensitiveKey: SecKey = SecKeyCreateWithData(decryptedSensitiveKeyData! as CFData, try KeychainItem.ecKeyPair.creationAttributes(), &error) else {
            // will fail here if password was wrong
            throw error!.takeRetainedValue() as Error
        }
        sensitiveKey = decryptedSensitiveKey
    }


    func lock() {
        sensitiveKey = nil
    }

    func `import`(id: DataID, data: Data) throws {
        let pubKey = try store.find(.ecPubKey(tag: ProtectedKeyStore.publicKeyTag, service: protectionClass.service())) as! SecKey
        let encryptedSigningKey = try data.encrypt(publicKey: pubKey)
        let item = KeychainItem.generic(account: id.id, service: protectionClass.service(), data: encryptedSigningKey)
        try store.create(item)
    }

    func delete(id: DataID) throws {
        let item = KeychainItem.generic(account: id.id, service: protectionClass.service())
        try store.delete(item)
    }

    func authenticate(password userPassword: String? = nil) throws {
        let encryptedSensitiveKey = try store.find(KeychainItem.generic(account: ProtectedKeyStore.encryptedPrivateKeyTag, service: protectionClass.service())) as? Data
        let passwordData = userPassword != nil ? userPassword?.data(using: .utf8) : try store.find(KeychainItem.generic(account: ProtectedKeyStore.derivedPasswordTag, service: protectionClass.service())) as! Data?
        let sensitiveKEK = try store.find(KeychainItem.enclaveKey(tag: ProtectedKeyStore.privateKEKTag, service: protectionClass.service(), password: passwordData)) as! SecKey

        // Decrypt sensitive key
        let decryptedSensitiveKeyData = try encryptedSensitiveKey?.decrypt(privateKey: sensitiveKEK)
        var error: Unmanaged<CFError>?
        guard let _ = SecKeyCreateWithData(decryptedSensitiveKeyData! as CFData, try KeychainItem.ecKeyPair.creationAttributes(), &error) else {
            // will fail here if password was wrong
            throw error!.takeRetainedValue() as Error
        }
    }

    func find(dataID: DataID, password derivedPassword: String?, forceUnlock: Bool = false) throws -> Data? {
        guard let encryptedData = try store.find(KeychainItem.generic(account: dataID.id, service: protectionClass.service())) as? Data else {
            return nil
        }

        let locked = !unlocked

        if locked || forceUnlock {
            try unlock(derivedPassword: derivedPassword)
        }

        let result = try encryptedData.decrypt(privateKey: sensitiveKey!)

        if locked {
            lock()
        }

        return result
    }

    // Options:
    //          userCreatedAppPasscode -> true/false
    //                     -> oldPassword == nil  and/or newPassword == nil
    //                        oldPassword == nil -> use stored password to access current KEK
    //                        newPassword == nil -> use stored password to access KEK
    //          useBiometry -> true/false
    func changePassword(from oldPassword: String?, to newPassword: String?, useBiometry: Bool = false, keepUnlocked: Bool = false) throws {

        let wasLocked = !unlocked

        if wasLocked {
            try unlock(derivedPassword: oldPassword)
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
        let encryptedPK = try Data(secKey: sensitiveKey!).encrypt(publicKey: keyEncryptionKey.publicKey())

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
                publicKey: sensitiveKey!.publicKey()
        )
        try store.create(pubKeyItem)

        if wasLocked && !keepUnlocked {
            lock()
        }
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
        try store.delete(.generic(account: ProtectedKeyStore.derivedPasswordTag, service: protectionClass.service()))
        try store.delete(.generic(account: ProtectedKeyStore.encryptedPrivateKeyTag, service: protectionClass.service()))
        try store.delete(.ecPubKey(tag: ProtectedKeyStore.publicKeyTag, service: protectionClass.service()))
        try store.delete(.enclaveKey(tag: ProtectedKeyStore.privateKEKTag, service: protectionClass.service()))
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
        guard let decryptedData = SecKeyCreateDecryptedData(privateKey, .eciesEncryptionStandardX963SHA256AESGCM, self as CFData, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        return decryptedData as Data
    }
}

extension SecKey {
    func publicKey() -> SecKey {
        // extract public key using SecKeyCopyPublicKey
        SecKeyCopyPublicKey(self)!
    }
}
