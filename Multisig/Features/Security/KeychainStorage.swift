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

    static let sensitivePublicKeyTag = "global.safe.sensitivePublicKeyTag"
    static let sensitivePublicKekTag = "global.safe.sensitivePublicKEKTag"
    static let sensitivePrivateKekTag = "global.safe.sensitivePrivateKEKTag"
    static let sensitiveEncryptedPrivateKeyTag = "global.safe.sensitive.private.key.as.encrypted.data"
    static let derivedPasswordTag = "global.safe.password.as.data"

    // store passcode. Either if it random (user didn't give a password) or the user asked us to remember it
    func storePasscode(passcode: String) throws {
        try storeItem(item: KeychainItem.generic(id: KeychainStorage.derivedPasswordTag, service: ProtectionClass.sensitive.service(), data: passcode.data(using: .utf8)))
    }

    func retrievePasscode() -> String? {
        // Retrieve password from persistence
        do {
            if let passCodeData = try findItem(item: KeychainItem.generic(id: KeychainStorage.derivedPasswordTag, service: ProtectionClass.sensitive.service())) {
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

    private func findItem(item: KeychainItem) throws -> Data? {
        let query = item.searchQuery()
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
        return try createKeyPair(KeychainItem.enclaveKey(password: applicationPassword.data(using: .utf8), access: flags))
    }

    func retrieveEncryptedData(dataID: DataID) throws -> Data? {
        let query = KeychainItem.generic(id: dataID.id, service: dataID.protectionClass.service()).searchQuery()

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

    func storeItem(item: KeychainItem) throws {
        try deleteItem(item)
        // We pass nil here because we do not need to return a copy of the stored item
        let status = SecItemAdd(try item.creationAttributes(), nil)
        guard status == errSecSuccess else {
            throw GSError.GenericPasscodeError(reason: "Cannot store public key")
        }
    }

    func retrieveSensitivePublicKey() throws -> SecKey? {
        try findKey(query: KeychainItem.ecPubKey())
    }

    func createKeyPair(_ item: KeychainItem = KeychainItem.ecKeyPair) throws -> SecKey {
        // .ecKeyPair keys are not stored automatically. So we do not need to delete them here
        if item != KeychainItem.ecKeyPair  {
            try deleteItem(item)
        }
        let attributes = try item.creationAttributes()

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

    func deleteItem(_ query: KeychainItem) throws {
        let status = SecItemDelete(query.searchQuery())

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw convertStatusToError(status: status)
        }
    }

    func findKey(query: KeychainItem) throws -> SecKey? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query.searchQuery(), &item)
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
