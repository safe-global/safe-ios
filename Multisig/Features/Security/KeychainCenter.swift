//
//  KeychainCenter.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class KeychainCenter {

    private var sensitiveKey: SecKey? = nil

    init() {
        passcode = "<empty>"
    }

    var passcode: String

    // store passcode. Either if it random (user didn't give a password) or the user asked us to remember it
    func storePasscode(derivedPasscode: String) {
        App.shared.snackbar.show(message: "storePasscode(): derivedPasscode: \(derivedPasscode)")
        passcode = derivedPasscode
    }

    func retrievePasscode() -> String {
        App.shared.snackbar.show(message: "retrievePasscode(): derivedPasscode: \(passcode)")
        return passcode
    }

    // used to create KEK
    func createSecureEnclaveKey(
            useBiometry: Bool,
            canChangeBiometry: Bool,
            passcode: String
    ) throws -> SecKey {

        let key = try createSEKey(tag: "global.safe.sensitive.KEK")

        return key // return tag as well?
    }

    func storeSensitiveKey(secKey: SecKey) {
        let tag = "global.safe.sensitive.key"
        App.shared.snackbar.show(message: "storeSensitiveKey(): secKey: \(secKey)")

        // TODO save encrypted sensitive_key to to keychain
        // serialize
        // encrypt with KEK
        // safe to Keychain (as type password?) using SecItemAdd()

        sensitiveKey = secKey
    }
    private func createSEKey(flags: SecAccessControlCreateFlags = [.userPresence],
                             tag: String
    ) throws -> SecKey {
        let protection: CFString = kSecAttrAccessibleWhenUnlocked

        // create access control flags with params
        var accessError: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlocked, // TODO necessary? useful?
                .privateKeyUsage.union(flags),
                &accessError
        )
        else {
            throw accessError!.takeRetainedValue() as Error
        }

        // create attributes dictionary
        let attributes: NSDictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs: [ 
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: tag.data(using: .utf8)!,
                kSecAttrAccessControl: access
            ]
        ]

        // create a key pair
        var createError: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes, &createError) else {
            throw createError!.takeRetainedValue() as Error
        }

        return privateKey
    }


    // used to create a public-private key pair (asymmetric) NOT in secure enclave
    func createKeyPair() throws -> SecKey {
        let attributes: NSDictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
        ]
        var createError: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes, &createError) else {
            LogService.shared.error(" --> CreateError: \(createError)")
            throw createError!.takeRetainedValue() as Error
        }
        return privateKey
    }

    // used to find a KEK or a private key
    func findPrivateKey() {}

    func findPublicKey() {}

    func deleteItem(tag: String) {}

    func saveItem(data: Data, tag: String) {}

    func findItem(tag: String) -> Data? {
        preconditionFailure()
    }

    func encrypt() {

    }

    func decrypt() {
    }

}
