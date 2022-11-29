//
// Created by Dirk Jäckel on 15.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import CommonCrypto
import CryptoKit

class SensitiveEncryptedStore: EncryptedStore {

    let keychainStorage: KeychainStorage

    init(_ keychainStorage: KeychainStorage) {
        self.keychainStorage = keychainStorage
    }

    init() {
        keychainStorage = KeychainStorage()
    }

    func isInitialized() -> Bool {
        do {
            return try keychainStorage.findKey(query: KeychainStoreItem.ecPubKey()) != nil
        } catch {
            return false
        }
    }

    // This is called, when using the new key security is activated after updating the app. Even if the user did not activate it.
    func initializeKeyStore() throws {
        let passcode = try persistRandomPassword()
        let sensitiveKey = try keychainStorage.createKeyPair()
        try persistSensitivePublicKey(sensitiveKey: sensitiveKey)
        let sensitiveKEK = try keychainStorage.createSecureEnclaveKey(
                useBiometry: false,
                canChangeBiometry: true,
                applicationPassword: passcode
        )
        try persistSensitivePrivateKey(passcode: passcode, sensitiveKey: sensitiveKey, sensitiveKEK: sensitiveKEK)
    }

    private func persistRandomPassword() throws -> String {
        let randomPasscode = createRandomPassword()!
        try keychainStorage.storePasscode(passcode: randomPasscode)
        return randomPasscode
    }

    private func createRandomPassword() -> String? {
        var bytes: [UInt8] = .init(repeating: 0, count: 32)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard result == errSecSuccess else {
            return nil
        }
        return bytes.toHexString()
    }

    private func persistSensitivePrivateKey(passcode: String, sensitiveKey: SecKey, sensitiveKEK: SecKey) throws { // create SE key (KEK) with a hard coded tag for example: "sensitive_KEK"
        // Convert SecKey -> Data SecKeyCopyExternalRepresentation -> CFData -> Data
        // Copy private part of sensitive key
        var error: Unmanaged<CFError>?
        guard let sensitiveKeyData = SecKeyCopyExternalRepresentation(sensitiveKey, &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        // Copy public KEK Key to encrypt sensitive key)
        let sensitivePublicKek = SecKeyCopyPublicKey(sensitiveKEK)
        try keychainStorage.storeItem(item: KeychainStoreItem.ecPubKey(tag: KeychainStorage.sensitivePublicKekTag, publicKey: sensitivePublicKek))
        // encrypt private part of sensitive_key
        // encrypt data using sensitiveKEK
        let encryptedSensitiveKey = try encrypt(publicKey: sensitivePublicKek, plainText: sensitiveKeyData)
        // Store encrypted sensitive private key in keychain as blob
        try keychainStorage.storeItem(item: KeychainStoreItem.generic(id: KeychainStorage.sensitiveEncryptedPrivateKeyTag, service: ProtectionClass.sensitive.service(),data: encryptedSensitiveKey))
    }

    private func persistSensitivePublicKey(sensitiveKey: SecKey) throws { // copy public part from SecKey
        let sensitivePublicKey = SecKeyCopyPublicKey(sensitiveKey)
        // safe it via keychainStorage.storeSensitivePublicKey()
        if let key = sensitivePublicKey {
            try keychainStorage.storeItem(item: KeychainStoreItem.ecPubKey(publicKey: key))
        } else {
            throw GSError.GenericPasscodeError(reason: "Cannot copy public key")
        }
    }

    func `import`(id: DataID, ethPrivateKey: EthPrivateKey) throws {
        LogService.shared.info("ethPrivateKey: \(ethPrivateKey.toHexString())")
        //1. create key from Data
        let privateKey = try PrivateKey(data: ethPrivateKey)
        LogService.shared.info("privateKey: \(privateKey)")

        // 2. find public sensitive key
        let pubKey = try keychainStorage.retrieveSensitivePublicKey()
        LogService.shared.info("pubKey: \(pubKey)")

        // 3. encrypt private key with public sensitive key
        var error: Unmanaged<CFError>?

        let encryptedSigningKey = try encrypt(publicKey: pubKey!, plainText: ethPrivateKey)
        LogService.shared.info("encryptedSigningKey: \(encryptedSigningKey)")

        // 4. store encrypted blob in the keychain
        let address = privateKey.address
        try keychainStorage.storeItem(item: KeychainStoreItem.generic(id: id.id, service: id.protectionClass.service(), data: encryptedSigningKey))
        LogService.shared.info("done.")

    }

    /// Find private signer key.
    /// - parameter address: find ky for this address
    /// - parameter password: application password. Can be nil, then the sored password is used
    /// - returns: String with hex encoded bytes of the private key
    func find(dataID: DataID, password: String? = nil) throws -> EthPrivateKey? {
        // find encrypted private key for the address
        guard let encryptedPrivateKeyData = try? keychainStorage.retrieveEncryptedData(dataID: dataID) else {
            return nil
        }

        // find sensitiveKEK
        let password = password != nil ? password : keychainStorage.retrievePasscode()
        let sensitiveKEK = try keychainStorage.findKey(query: KeychainStoreItem.enclaveKey(password: password?.data(using: .utf8)))!

        // find encrypted sensitive key
        let encryptedSensitiveKeyData = try keychainStorage.retrieveEncryptedData(dataID: DataID(id: KeychainStorage.sensitiveEncryptedPrivateKeyTag, protectionClass: .sensitive))!

        // decrypt encrypted sensitive key
        var error: Unmanaged<CFError>?
        let decryptedSensitiveKeyData = try decrypt(privateKey: sensitiveKEK, encryptedData: encryptedSensitiveKeyData)
        // Data -> key
        guard let decryptedSensitiveKey: SecKey = SecKeyCreateWithData(decryptedSensitiveKeyData as CFData, try KeychainStoreItem.ecKeyPair.createAttributesForItem(), &error) else {
            // will fail here if password was wrong
            throw error!.takeRetainedValue() as Error
        }
        LogService.shared.debug("decryptedSensitiveKey: \(decryptedSensitiveKey)")
        // decrypt the eth key with sensitive key
        let decryptedEthKeyData = try decrypt(privateKey: decryptedSensitiveKey, encryptedData: encryptedPrivateKeyData)

        // return private key
        return decryptedEthKeyData
    }

    func changePassword(from oldPassword: String, to newPassword: String) {
        // create a new kek
        // decrypt private senstivie key with kek
        // encrypt sensitive key with new kek

        // decrypt data key with old data kek
        // encrypt data key with new data kek
    }

    func changeSettings() {
        // Settings

        //  change password
        //  enable / disable password

        //  use biometry
        //  use password in addition to face id when signing

    }

    func delete(address: Address) {
        // delete encrypted blob by address
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

