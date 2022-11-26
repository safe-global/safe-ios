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

    // This is called, when using the new key security is activated after updating the app. Even if the user did not activate it.
    func initializeKeyStore() throws {
        let derivedPasscode = try persistRandomPassword()
        let sensitiveKey = try keychainStorage.createKeyPair()
        try persistSensitivePublicKey(sensitiveKey: sensitiveKey)
        try persistSensitivePrivateKey(derivedPasscode: derivedPasscode, sensitiveKey: sensitiveKey)
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

    private func persistSensitivePrivateKey(derivedPasscode: String, sensitiveKey: SecKey) throws { // create SE key (KEK) with a hard coded tag for example: "sensitive_KEK"
        let sensitiveKEK = try keychainStorage.createSecureEnclaveKey(
                useBiometry: false,
                canChangeBiometry: true,
                applicationPassword: derivedPasscode
        )

        // Convert SecKey -> Data SecKeyCopyExternalRepresentation -> CFData -> Data
        // Copy private part of sensitive key
        var error: Unmanaged<CFError>?
        guard let sensitiveKeyData = SecKeyCopyExternalRepresentation(sensitiveKey, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        LogService.shared.info("sensitiveKeyData: \((sensitiveKeyData as Data).toHexString())")

        // Copy public KEK Key to encrypt sensitive key)
        let sensitivePublicKek = SecKeyCopyPublicKey(sensitiveKEK)
        // encrypt private part of sensitive_key
        // encrypt data using: SecKeyCreateEncryptedData using sensitiveKEK
        guard let encryptedSensitiveKey = SecKeyCreateEncryptedData(sensitivePublicKek!, .eciesEncryptionStandardX963SHA256AESGCM, sensitiveKeyData, &error) as? Data else {
            throw error!.takeRetainedValue() as Error
        }
        // Store encrypted sensitive private key in keychain as blob
//        try keychainStorage.storeData(encryptedData: encryptedSensitiveKey, account: KeychainStorage.sensitiveEncryptedPrivateKeyTag)

        //try keychainStorage.deleteItem(ItemSearchQuery.generic(id: KeychainStorage.sensitiveEncryptedPrivateKeyTag))
        try keychainStorage.storeItem(item: ItemSearchQuery.generic(id: KeychainStorage.sensitiveEncryptedPrivateKeyTag, data: encryptedSensitiveKey))
    }

    private func persistSensitivePublicKey(sensitiveKey: SecKey) throws { // copy public part from SecKey
        let sensitivePublicKey = SecKeyCopyPublicKey(sensitiveKey)
        // safe it via keychainStorage.storeSensitivePublicKey()
        if let key = sensitivePublicKey {
            try keychainStorage.storeItem(item: ItemSearchQuery.ecPubKey(publicKey: key))
        } else {
            throw GSError.GenericPasscodeError(reason: "Cannot copy public key")
        }
    }

    func `import`(ethPrivateKey: EthPrivateKey) throws {
        LogService.shared.info("ethPrivateKey: \(ethPrivateKey)")
        // 0. Converts hexString to Data
        let privateKeyData: Data = Data(ethHex: ethPrivateKey)
        //1. create key from String
        let privateKey = try PrivateKey(data: privateKeyData)
        // 2. find public sensitive key
        let pubKey = try keychainStorage.retrieveSensitivePublicKey()
        // 3. encrypt private key with public sensitive key
        var error: Unmanaged<CFError>?
        guard let encryptedSigningKey = SecKeyCreateEncryptedData(pubKey!, .eciesEncryptionStandardX963SHA256AESGCM, privateKeyData as CFData, &error) as? Data else {
            throw error!.takeRetainedValue() as Error
        }
        // 4. store encrypted blob in the keychain
        let address = privateKey.address
        try keychainStorage.storeItem(item: ItemSearchQuery.generic(id: address.checksummed, data: encryptedSigningKey))
    }

    /// Find private signer key.
    /// - parameter address: find ky for this address
    /// - parameter password: application password. Can be nil, then the sored password is used
    /// - returns: String with hex encoded bytes of the private key
    func find(address: Address, password: String? = nil) throws -> EthPrivateKey? {
        // find encrypted private key for the address
        guard let encryptedPrivateKeyData = try? keychainStorage.retrieveEncryptedData(account: address.checksummed) else {
            return nil
        }

        // find sensitiveKEK
        let password = password != nil ? password : keychainStorage.retrievePasscode()
        let sensitiveKEK = try keychainStorage.findKey(query: ItemSearchQuery.enclaveKey(password: password?.data(using: .utf8)))!

        // find encrypted sensitive key
        let encryptedSensitiveKeyData = try keychainStorage.retrieveEncryptedData(account: KeychainStorage.sensitiveEncryptedPrivateKeyTag)!

        // decrypt encrypted sensitive key
        var error: Unmanaged<CFError>?
        guard let decryptedSensitiveKeyData = SecKeyCreateDecryptedData(sensitiveKEK, .eciesEncryptionStandardX963SHA256AESGCM, encryptedSensitiveKeyData as CFData, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        // Data -> key
        LogService.shared.debug("decryptedSensitiveKeyData: \((decryptedSensitiveKeyData as Data).toHexString())")
        let attributes: NSDictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate
        ]
        guard let decryptedSensitiveKey: SecKey = SecKeyCreateWithData(decryptedSensitiveKeyData, attributes, &error) else {
            // will fail here if password was wrong
            throw error!.takeRetainedValue() as Error
        }
        LogService.shared.debug("decryptedSensitiveKey: \(decryptedSensitiveKey)")
        // decrypt the eth key with sensitive key
        let decryptedEthKeyData = SecKeyCreateDecryptedData(decryptedSensitiveKey, .eciesEncryptionStandardX963SHA256AESGCM, encryptedPrivateKeyData as CFData, &error) as? Data

        // Data -> String key
        let decryptedEthKey = decryptedEthKeyData!.toHexString()
        // return private key
        return decryptedEthKey
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

    // Copied from AuthenticationController
    private func derivePasscode(from plaintext: String, useOldSalt: Bool = false) -> String {
        let salt = "Safe Multisig Passcode Salt"
        var derivedKey = [UInt8](repeating: 0, count: 256 / 8)
        let result = CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                plaintext,
                plaintext.lengthOfBytes(using: .utf8),
                salt,
                salt.lengthOfBytes(using: .utf8),
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                500_000,
                &derivedKey,
                derivedKey.count)
        guard result == kCCSuccess else {
            LogService.shared.error("Failed to derive key", error: "Failed to derive a key: \(result)")
            return plaintext
        }
        return Data(derivedKey).toHexString()
    }
}

