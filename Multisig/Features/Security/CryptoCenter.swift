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

class CryptoCenter {

    typealias EthPrivateKey = String

    let keychainCenter: KeychainCenter

    init() {
        keychainCenter = KeychainCenter()
    }

    // This is called, when using the new key security is activated after updating the app. Even if the user did not activate it.
    func initialSetup(
            passcodeEnabled: Bool = false,
            useBiometry: Bool = false,
            canChangeBiometry: Bool = true,
            rememberPasscode: Bool = true, // that would be the randomly generated passcode
            passcode: String? = nil
    ) throws {

        // QUESTION: Should we have access/know about to AppSetting.passcodeOptions here?

        // check if setup has happened already by checking if there is a sensitive key in the keychain?

        // precondition:
        // if passcodeEnabled then passcode must not be null
        if passcodeEnabled && passcode == nil {
            throw GSError.GenericPasscodeError(reason: "Passcode missing") // Do we need a more specific error here?
        }

        var derivedPasscode: String = ""
        if (!passcodeEnabled) {
            // if !passcodeEnabled -> create random key and store in Keychain
            let randomPasscode = createRandomPassword()
            App.shared.snackbar.show(message: "randomPasscode: \(randomPasscode)")
            derivedPasscode = derivePasscode(from: randomPasscode)
        } else {
            derivedPasscode = derivePasscode(from: passcode!)
        }
        // if rememberPasscode -> store passcode in keychain
        // if !passcodeEnabled -> store passcode in keychain
        if (rememberPasscode || !passcodeEnabled) {
            keychainCenter.storePasscode(derivedPasscode: derivedPasscode) // check error?
        }

        // create sensitive_key
        let sensitiveKey = try keychainCenter.createKeyPair()

        // TODO Store sensitive public key in keychain
        // copy public part from SecKey
        let sensitivePublicKey = SecKeyCopyPublicKey(sensitiveKey)
        // safe it via keychainCenter.storeSensitivePublicKey()
        if let key = sensitivePublicKey {
            keychainCenter.storeSensitivePublicKey(publicKey: key)
        } else {
            App.shared.snackbar.show(message: "Cannot copy public key")
            throw GSError.GenericPasscodeError(reason: "Cannot copy public key")
        }

        if !SecureEnclave.isAvailable {
            App.shared.snackbar.show(message: "Secure Enclave not available")
        } else {
            App.shared.snackbar.show(message: "Secure Enclave is available")
        }

        // create SE key (KEK) with a hard coded tag for example: "sensitive_KEK"
        let sensitiveKEK = try keychainCenter.createSecureEnclaveKey(
                useBiometry: useBiometry,
                canChangeBiometry: canChangeBiometry,
                applicationPassword: derivedPasscode
        )

        // TODO encrypt private part of sensitive_key
        // Convert SecKey -> Data SecKeyCopyExternalRepresentation -> CFData -> Data
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(sensitiveKey, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        // encrypt data using: SecKeyCreateEncryptedData using sensitiveKEK
        let sensitivePublicKek = SecKeyCopyPublicKey(sensitiveKEK)
        guard let encryptedSensitiveKey = SecKeyCreateEncryptedData(sensitivePublicKek!, .eciesEncryptionStandardX963SHA256AESGCM, data, &error) as? Data else {
            throw error!.takeRetainedValue() as Error
        }
        // store encrypted sensitive private key in keychain as blob
        keychainCenter.storeSensitiveKey(encryptedSensitiveKey: encryptedSensitiveKey)
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

    func verify() {}

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

