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
    func initialSetup() throws {
//        if !SecureEnclave.isAvailable {
//            App.shared.snackbar.show(message: "Secure Enclave not available")
//        } else {
//            App.shared.snackbar.show(message: "Secure Enclave is available")
//        }
        let derivedPasscode = persistRandomPassword()
        let sensitiveKey = try keychainStorage.createKeyPair()
        try persistSensitivePublicKey(sensitiveKey: sensitiveKey)
        try persistSensitivePrivateKey(derivedPasscode: derivedPasscode, sensitiveKey: sensitiveKey)
    }

    private func persistRandomPassword() -> String {
        let randomPasscode = createRandomPassword()
        let derivedPasscode = derivePasscode(from: randomPasscode)
        keychainStorage.storePasscode(derivedPasscode: derivedPasscode) // TODO check error?
        return derivedPasscode
    }

    private func createRandomPassword() -> String {
        // TODO: What do we do if there is not enough randomness available?
        Data.randomBytes(length: 32)!.toHexString()
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
        LogService.shared.info("| ---> sensitiveKeyData: \((sensitiveKeyData as Data).toHexString())")

        // Copy public KEK Key to encrypt sensitive key)
        let sensitivePublicKek = SecKeyCopyPublicKey(sensitiveKEK)
        // encrypt private part of sensitive_key
        // encrypt data using: SecKeyCreateEncryptedData using sensitiveKEK
        guard let encryptedSensitiveKey = SecKeyCreateEncryptedData(sensitivePublicKek!, .eciesEncryptionStandardX963SHA256AESGCM, sensitiveKeyData, &error) as? Data else {
            throw error!.takeRetainedValue() as Error
        }
        // Store encrypted sensitive private key in keychain as blob
        keychainStorage.storeSensitivePrivateKey(encryptedSensitiveKey: encryptedSensitiveKey)
    }

    private func persistSensitivePublicKey(sensitiveKey: SecKey) throws { // copy public part from SecKey
        let sensitivePublicKey = SecKeyCopyPublicKey(sensitiveKey)
        // safe it via keychainStorage.storeSensitivePublicKey()
        if let key = sensitivePublicKey {
            try keychainStorage.storeSensitivePublicKey(publicKey: key)
        } else {
            throw GSError.GenericPasscodeError(reason: "Cannot copy public key")
        }
    }

    func `import`(privateKey: EthPrivateKey) {
        // store encrypted key for the address
        // find public sensitive key
        // encrypt private key with public sensitive key
        // store encrypted blob in the keychain
    }

    func delete(address: Address) {
        // delete encrypted blob by address
    }

    func sign(data: Data, address: Address, password: String) -> Signature {
        // find encrypted private key for the address
        // decrypt encrypted private key
        // find encrypted sensitive key
        // decrypt encrypted sensitive key
        // find key encryption key
        // set password credentials
        // decrypt sensitive key
        // decrypt the private key with sensitive key
        // sign data with private key
        // return signature
        preconditionFailure()
    }

    func verify() {
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

