//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

public enum KeychainError: Error {

    // https://www.osstatus.com
    case unhandledError(status: String)

}

public final class KeychainService: SecureStore {

    private let serviceIdentifier: String

    public init(identifier: String) {
        serviceIdentifier = identifier
    }

    public func save(data: Data, forKey key: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecAttrService as String: serviceIdentifier,
                                    kSecValueData as String: data]
        try add(query: query)
    }

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

    public func removeData(forKey key: String) throws {
        try remove(query: [kSecClass as String: kSecClassGenericPassword,
                           kSecAttrAccount as String: key,
                           kSecAttrService as String: serviceIdentifier])
    }

    public func destroy() throws {
        try remove(query: [kSecClass as String: kSecClassGenericPassword,
                           kSecAttrService as String: serviceIdentifier])
    }

    private func get(query: [String: Any]) throws -> CFTypeRef? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: securityError(status))
        }
        return item
    }

    private func securityError(_ status: OSStatus) -> String {
        if #available(iOS 11.3, *) {
            if let str = SecCopyErrorMessageString(status, nil) as String? {
                return str
            }
        }
        return String(describing: status)
    }

    private func add(query: [String: Any]) throws {
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: securityError(status))
        }
    }

    private func remove(query: [String: Any]) throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: securityError(status))
        }
    }

}
