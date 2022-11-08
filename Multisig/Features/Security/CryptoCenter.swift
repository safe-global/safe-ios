//
//  CryptoCenter.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import CommonCrypto

class CryptoCenter {

    typealias EthPrivateKey = String

    let keychainCenter: KeychainCenter

    init() {
        keychainCenter = KeychainCenter()
    }

    func initialSetup(
            passcodeEnabled: Bool = false,
            useBiometry: Bool,
            canChangeBiometry: Bool,
            rememberPasscode: Bool,
            protectAppOpen: Bool,
            protectKeyAccess: Bool,
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
        let sensitiveKey = try createSensitiveKey() // TODO: fails :-(
        keychainCenter.storeSensitiveKey(secKey: sensitiveKey)

        // create SE key (KEK) with a hard coded tag for example: "sensitive_KEK"
        // encrypt private part of sensitive_key
        // store encrypted sensitive key in keychain as blob

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

    private func createSensitiveKey() throws -> SecKey {
       try keychainCenter.createKeyPair()
    }
}

