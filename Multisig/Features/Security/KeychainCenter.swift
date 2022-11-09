//
//  KeychainCenter.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import CommonCrypto
import LocalAuthentication

class KeychainCenter {

    private var sensitiveKey: Data? = nil
    private var sensitivePublicKey: SecKey? = nil

    init() {
        passcode = "<empty>"
    }

    var passcode: String

    // store passcode. Either if it random (user didn't give a password) or the user asked us to remember it
    func storePasscode(derivedPasscode: String) {
        App.shared.snackbar.show(message: "storePasscode(): derivedPasscode: \(derivedPasscode)")

        // TODO Persist password



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
            applicationPassword: String
    ) throws -> SecKey {

        //create flags from booleans
        var flags: SecAccessControlCreateFlags = []
        if canChangeBiometry && useBiometry {
            flags = [.biometryAny, .or, .devicePasscode, .applicationPassword]
        }
        if !canChangeBiometry && useBiometry {
            flags = [.biometryCurrentSet, .or, .devicePasscode, .applicationPassword]
        }
        if !useBiometry {
            flags = [.devicePasscode, .applicationPassword]
        }

        // TODO pass password in LAContext?
        let authenticationContext = LAContext()
        let applicationPassword = applicationPassword.data(using: .utf8)
        let result = authenticationContext.setCredential(applicationPassword, type: .applicationPassword) // this should set the applicationPassword and not ask user for one. result is tru. But app asks for password anyway.
        App.shared.snackbar.show(message: "setCredential(): \(result)")

        let key = try createSEKey(flags: flags, tag: "global.safe.sensitive.KEK")

        return key // return tag as well?
    }

    func storeSensitiveKey(encryptedSensitiveKey: Data) {
        let tag = "global.safe.sensitive.private.key.as.encrypted.data"
        App.shared.snackbar.show(message: "storeSensitiveKey(): secKey: \(encryptedSensitiveKey)")

        // TODO save encrypted sensitive_key to to keychain
        // safe to Keychain (as type password?) using SecItemAdd()
        //SecItemAdd()
        sensitiveKey = encryptedSensitiveKey
    }

    func storeSensitivePublicKey(publicKey: SecKey) {
        let tag = "global.safe.sensitive.public.key"
        App.shared.snackbar.show(message: "storeSensitivePublicKey(): publicKey: \(publicKey)")

        // TODO save to keychain
        //SecItemAdd(<#T##attributes: CFDictionary##CoreFoundation.CFDictionary#>, <#T##result: UnsafeMutablePointer<CFTypeRef?>?##Swift.UnsafeMutablePointer<CoreFoundation.CFTypeRef?>?#>)

        sensitivePublicKey = publicKey
    }

    private func createSEKey(flags: SecAccessControlCreateFlags, tag: String) throws -> SecKey {
        let protection: CFString = kSecAttrAccessibleWhenUnlocked

        // create access control flags with params
        var accessError: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlocked, // TODO necessary? useful? Available: kSecAttrAccessibleWhenPasscodeSet ?
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
