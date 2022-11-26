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

class KeychainStorage {

    static let sensitivePublicKeyTag = "global.safe.sensitive.public.key"
    static let sensitiveEncryptedPrivateKeyTag = "global.safe.sensitive.private.key.as.encrypted.data"
    static let derivedPasswordTag = "global.safe.password.as.data"
    static let sensitiveKekTag = "global.safe.sensitive.KEK"

    // used to store encrypted data as a password in keychain
    static let defaultService: String = "global.safe.sensitive.encrypted.data"

    // store passcode. Either if it random (user didn't give a password) or the user asked us to remember it
    func storePasscode(passcode: String) throws {
        try storeItem(item: ItemSearchQuery.generic(id: KeychainStorage.derivedPasswordTag, data: passcode.data(using: .utf8)))
    }

    func retrievePasscode() -> String? {
        // Retrieve password from persistence
        do {
            if let passCodeData = try findItem(item: ItemSearchQuery.generic(id: KeychainStorage.derivedPasswordTag)) {
                return String.init(data: passCodeData, encoding: .utf8)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    private func convertStatusToError(status: OSStatus) -> Error {
        let message = SecCopyErrorMessageString(status, nil) as? String ?? String(status)
        return NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func findItem(item: ItemSearchQuery) throws -> Data? {
        let query = item.createSearchQuery()
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)

        switch status {
        case errSecSuccess:
            if let item = item {
                return item as? Data
            } else {
                return nil
            }

        case errSecItemNotFound:
            return nil

        case let status:
            throw convertStatusToError(status: status)
        }
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
            flags = [.applicationPassword]
        }
        return try createSEKey(flags: flags, applicationPassword: applicationPassword)
    }

    func retrieveEncryptedData(account: String) throws -> Data? {
        let query = ItemSearchQuery.generic(id: account).createSearchQuery()

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)

        switch status {
        case errSecSuccess:
            if let item = item {
                return item as? Data
            } else {
                return nil
            }

        case errSecItemNotFound:
            return nil

        case let status:
            throw convertStatusToError(status: status)
        }
    }

    func storeItem(item: ItemSearchQuery) throws {
        try deleteItem(item)

        let status = SecItemAdd(try item.createAttributesForItem(), nil)
        guard status == errSecSuccess else {
            throw GSError.GenericPasscodeError(reason: "Cannot store public key")
        }
    }

    func retrieveSensitivePublicKey() throws -> SecKey? {
        try findKey(query: ItemSearchQuery.ecPubKey())
    }

    private func createSEKey(flags: SecAccessControlCreateFlags, applicationPassword: String) throws -> SecKey {
        // Passed via kSecUseAuthenticationContext to kSecPrivateKeyAttrs attributes
        try deleteItem(.enclaveKey())
        let attributes = try ItemSearchQuery.enclaveKey().createAttributesForItem(access: .applicationPassword, password: applicationPassword.data(using: .utf8))

        // create a key pair
        var createError: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes, &createError) else {
            throw createError!.takeRetainedValue() as Error
        }

        return privateKey
    }

    private func createLAContextFromPassword(password: String) -> (Bool, LAContext) {
        let authenticationContext = LAContext()
        let passwordData = password.data(using: .utf8)
        // setCredential() returns false on the Simulator.
        // This means on the simulator the created SE key is not protected by the application password.
        let result = authenticationContext.setCredential(passwordData, type: .applicationPassword)

        return (result, authenticationContext)
    }

    // used to create a public-private key pair (asymmetric) NOT in secure enclave -> Sensitive Key
    func createKeyPair() throws -> SecKey {
        let attributes = try ItemSearchQuery.ecKeyPair.createAttributesForItem()
        var error: Unmanaged<CFError>?
        guard let keyPair = SecKeyCreateRandomKey(attributes, &error) else {
            LogService.shared.error("Error: \(error!.takeRetainedValue() as Error)")
            throw error!.takeRetainedValue() as Error
        }
        return keyPair
    }

    func deleteItem(_ query: ItemSearchQuery) throws {
        let status = SecItemDelete(query.createSearchQuery())

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw convertStatusToError(status: status)
        }
    }

    func findKey(query: ItemSearchQuery) throws -> SecKey? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query.createSearchQuery(), &item)
        switch status {
        case errSecSuccess:
            let key = item as! SecKey
            return key

        case errSecItemNotFound:
            return nil

        case let status:
            throw convertStatusToError(status: status)
        }
    }
}
