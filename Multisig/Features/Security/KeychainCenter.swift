//
//  KeychainCenter.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class KeychainCenter {

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

        let key = try createSEKey(tag: "safe.sensitive.KEK")

        return key
    }

    func storeSensitiveKey(secKey: SecKey) {
        App.shared.snackbar.show(message: "storeSensitiveKey(): secKey: \(secKey)")
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


    // used to create a public-private key pair (asymmetric)
    func createKeyPair() throws -> SecKey {

        let tag = "safe.sensitive.key"

        // create access control flags with params
        var accessError: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleAlways, // TODO necessary? useful? Alternatives: kSecAttrAccessibleWhenUnlocked, kSecAttrAccessibleAfterFirstUnlock
                .privateKeyUsage,
                &accessError
        )
        else {
            LogService.shared.error(" --> AccessError: \(accessError)")
            throw accessError!.takeRetainedValue() as Error
        }

        // create attributes dictionary
        let attributes: NSDictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: tag.data(using: .utf8)!,
                kSecAttrAccessControl: access
            ]
        ]

        // create a key pair
        var createError: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes, &createError) else {
//            LogService.shared.error("Error: \(error)")

        // TODO: Fails to create key on device with "Key generation failed, error -25293". But works on Simulator :-/
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
