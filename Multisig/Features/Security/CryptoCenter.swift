//
//  CryptoCenter.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import CommonCrypto
import CryptoKit

typealias EthPrivateKey = String

protocol CryptoCenter {
    func initialSetup() throws
    func `import`(privateKey: EthPrivateKey)
    func delete(address: Address)
    func sign(data: Data, address: Address, password: String) -> Signature
    func verify()
    func changePassword(from oldPassword: String, to newPassword: String)
    func changeSettings()
}

class CryptoCenterImpl: CryptoCenter {

    let keychainCenter: KeychainCenter

    init(_ keychainCenter: KeychainCenter) {
        self.keychainCenter = keychainCenter
    }

    init() {
        keychainCenter = KeychainCenter()
    }

    // This is called, when using the new key security is activated after updating the app. Even if the user did not activate it.
    func initialSetup() throws {
//        if !SecureEnclave.isAvailable {
//            App.shared.snackbar.show(message: "Secure Enclave not available")
//        } else {
//            App.shared.snackbar.show(message: "Secure Enclave is available")
//        }
        let derivedPasscode = persistRandomPassword()
        let sensitiveKey = try keychainCenter.createKeyPair()
        try persistSensitivePublicKey(sensitiveKey: sensitiveKey)
        try persistSensitivePrivateKey(derivedPasscode: derivedPasscode, sensitiveKey: sensitiveKey)
    }

    private func persistSensitivePrivateKey(derivedPasscode: String, sensitiveKey: SecKey) throws { // create SE key (KEK) with a hard coded tag for example: "sensitive_KEK"
        let sensitiveKEK = try keychainCenter.createSecureEnclaveKey(
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
        keychainCenter.storeSensitivePrivateKey(encryptedSensitiveKey: encryptedSensitiveKey)

        //retrieve encrypted sensitive key for DEBUGGING - TODO Replace with a proper test
        do {
            if let encryptedData: Data = try keychainCenter.findEncryptedSensitivePrivateKeyData() {
                LogService.shared.error(" ----> encryptedData found: \(encryptedData.toHexString())")

                // decrypt for debugging
                guard let decryptedSensitiveKey = SecKeyCreateDecryptedData(sensitiveKEK, .eciesEncryptionStandardX963SHA256AESGCM, encryptedData as CFData, &error) as? Data else {
                    throw error!.takeRetainedValue() as Error
                }

                LogService.shared.info("| ---> decryptedSensitiveKey: \(decryptedSensitiveKey.toHexString())")
                assert((sensitiveKeyData as Data).toHexString() == decryptedSensitiveKey.toHexString())
            } else {
                LogService.shared.error(" ---> encryptedData NOT found!")
            }

        } catch {
            LogService.shared.error(" ---> Error: \(error)")
        }
    }

    private func persistSensitivePublicKey(sensitiveKey: SecKey) throws { // copy public part from SecKey
        let sensitivePublicKey = SecKeyCopyPublicKey(sensitiveKey)
        // safe it via keychainCenter.storeSensitivePublicKey()
        if let key = sensitivePublicKey {
            try keychainCenter.storeSensitivePublicKey(publicKey: key)
            LogService.shared.error(" --->    key: \(key)")

            // For DEBUGGING - TODO should be replaced with a proper test
            let pubKeyFound = try keychainCenter.retrieveSensitivePublicKey()
            LogService.shared.info(" ---> pubKey: \(pubKeyFound!)")

            assert(key == pubKeyFound)

        } else {
            App.shared.snackbar.show(message: "Cannot copy public key")
            throw GSError.GenericPasscodeError(reason: "Cannot copy public key")
        }
    }

    private func persistRandomPassword() -> String {
        let randomPasscode = createRandomPassword()
        let derivedPasscode = derivePasscode(from: randomPasscode)
        keychainCenter.storePasscode(derivedPasscode: derivedPasscode) // TODO check error?
        let retrievedPasscode = keychainCenter.retrievePasscode()
        assert(retrievedPasscode == derivedPasscode)
        return derivedPasscode
    }

    private func createRandomPassword() -> String {
        // TODO: What do we do if there is not enough randomness available?
        Data.randomBytes(length: 32)!.toHexString()
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
        let salt = "Safe Multisig Passcode Salt"  // TODO Do we need to support the old salt?
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

