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
    internal init(store: KeychainStore) {
        self.store = store
    }

    private let store: KeychainStore

    func create(_ item: KeychainItem) throws -> Any {
        // delete if exists
        try store.delete(item.searchQuery())
        // create a new
        return try store.create(item.creationAttributes())
    }

    func find(_ item: KeychainItem) throws -> Any? {
        return try store.find(item.searchQuery())
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

        switch itemClass {
        case kSecClassKey:
            var error: Unmanaged<CFError>?
            guard let privateKey = SecKeyCreateRandomKey(attributes, &error) else {
                throw error!.takeRetainedValue() as Error
            }
            return privateKey

        case kSecClassGenericPassword:
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
