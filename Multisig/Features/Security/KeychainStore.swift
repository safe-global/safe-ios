//
//  KeychainStore.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 29.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

import CommonCrypto
import LocalAuthentication

// Thin wrapper around Keychain store
class KeychainItemStore {
    internal init(_ store: KeychainStore = KeychainStore()) {
        self.store = store
    }

    private let store: KeychainStore

    @discardableResult
    func create(_ item: KeychainItem) throws -> Any {
        switch item {
        case .ecKeyPair: break
        default:
            // delete if exists
            try store.delete(item.searchQuery())
        }
        // create a new
        return try store.create(item.creationAttributes())
    }

    func find(_ item: KeychainItem) throws -> Any? {
        try store.find(item.searchQuery())
    }

    func delete(_ item: KeychainItem) throws {
        try store.delete(item.searchQuery())
    }
}

// wrapper around Security/Keychain APIs
class KeychainStore {
    // attributes must contain the kSecClass
    // the value must be either key or generic password
    // must have kSecReturnData or kSecReturnRef (true) in attributes
    func create(_ attributes: NSDictionary) throws -> Any {
        let itemClass = attributes[kSecClass] as! CFString
        var keyType: CFString? = nil
        if attributes[kSecAttrKeyClass] != nil {
            keyType = attributes[kSecAttrKeyClass] as! CFString
        }
        switch (itemClass, keyType) {
        case (kSecClassKey, kSecAttrKeyClassPrivate):
            var error: Unmanaged<CFError>?
            guard let privateKey = SecKeyCreateRandomKey(attributes, &error) else {
                throw error!.takeRetainedValue() as Error
            }
            return privateKey
        case (kSecClassKey, kSecAttrKeyClassPublic):
            let status = SecItemAdd(attributes, nil)
            guard status == errSecSuccess else {
                throw GSError.GenericPasscodeError(reason: "Cannot store public key")
            }
            return attributes[kSecValueRef] as! CFData

        case (kSecClassGenericPassword, _):
            var item: CFTypeRef?
            let status = SecItemAdd(attributes, &item)
            guard status == errSecSuccess else {
                throw NSError(osstatus: status)
            }
            return item!

        default:
            preconditionFailure("Unsupported item class: \(itemClass)")
        }
    }

    // must have kSecReturnData or kSecReturnRef to be true
    func find(_ query: NSDictionary) throws -> Any? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        switch status {
        case errSecSuccess:
            return item!

        case errSecItemNotFound:
            return nil

        case let status:
            throw NSError(osstatus: status)
        }
    }

    func delete(_ query: NSDictionary) throws {
        let status = SecItemDelete(query)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NSError(osstatus: status)
        }
    }

}

extension NSError {
    convenience init(osstatus status: OSStatus) {
        let message = SecCopyErrorMessageString(status, nil) as? String ?? String(status)
        self.init(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: message])
    }
}
