//
//  KeychainService.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 10.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Implements the `SecureStore` protocol with iOS's Keychain api (`SecItem*` methods).
///
/// - Important: Because the underlying Keychain APIs work only within
/// an application bundle. That means, you can use this
/// class only within the context of an app. If you'll try to use this class, for example, in a unit test that
/// hasn't any host application, all Keychain APIs will fail and all methods will be throwing.
public final class KeychainService: SecureStore {
    private let serviceIdentifier: String

    /// Creates a new Keychain-based secure store that will store its data with `identifier` as a service name.
    ///
    /// - Parameter identifier: Name of the service to use for data stored in Keychain
    public init(identifier: String) {
        serviceIdentifier = identifier
    }

    /// Stores the Data as an account-password pair in the Keychain.
    /// The `data` is encrypted by the Keychain automatically.
    ///
    /// - Parameters:
    ///   - data: Arbitrary data for encrypted storage
    ///   - key: Key to associate with the stored data
    /// - Throws: The method will throw error if the key already exists in the store.
    public func save(data: Data, forKey key: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecAttrService as String: serviceIdentifier,
                                    kSecValueData as String: data]
        try add(query: query)
    }

    /// Finds the data associated with the `key`
    ///
    /// - Parameter key: Key to query the store
    /// - Returns: data or nil
    /// - Throws: May throw error if there was a problem with accessing Keychain.
    public func data(forKey key: String) throws -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: serviceIdentifier,
                                    kSecAttrAccount as String: key,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        guard let existingItem = try get(query: query) as? [String: Any],
            let data = existingItem[kSecValueData as String] as? Data else { return nil }
        return data
    }

    /// Returns all keys stored in the secured store
    ///
    /// - Throws: May throw error if there was a problem with accessing Keychain.
    /// - Returns: List of keys found.
    public func allKeys() throws -> [String] {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: serviceIdentifier,
                                    kSecMatchLimit as String: kSecMatchLimitAll,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: false]
        if let existingItems = try get(query: query) as? [[String: Any]] {
            let keys = existingItems.compactMap { $0[kSecAttrAccount as String] as? String }
            return keys
        }
        return []
    }

    /// Removes data associated with the key. If the key does not exist, this method is harmless.
    ///
    /// - Parameter key: Key to remove from the store.
    /// - Throws: May throw error if there was a problem with keychain.
    public func removeData(forKey key: String) throws {
        try remove(query: [kSecClass as String: kSecClassGenericPassword,
                           kSecAttrAccount as String: key,
                           kSecAttrService as String: serviceIdentifier])
    }

    /// Removes all keys stored with this service's `identifer` from the Keychain.
    ///
    /// - Throws: may throw error if there was a problem in the keychain.
    public func destroy() throws {
        try remove(query: [kSecClass as String: kSecClassGenericPassword,
                           kSecAttrService as String: serviceIdentifier])
    }

    private func get(query: [String: Any]) throws -> CFTypeRef? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else {
            throw GSError.KeychainError(reason: securityError(status))
        }
        return item
    }

    /// see https://www.osstatus.com to find description.
    private func securityError(_ status: OSStatus) -> String {
        let prefix = "OSStatus: \(status)"
        if let str = SecCopyErrorMessageString(status, nil) as String? {
            return prefix + str
        }
        return prefix
    }

    private func add(query: [String: Any]) throws {
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw GSError.KeychainError(reason: securityError(status))
        }
    }

    private func remove(query: [String: Any]) throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw GSError.KeychainError(reason: securityError(status))
        }
    }
}
