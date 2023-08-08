import Foundation

import Security

public class KeychainInterface {
    // Note: This class is provided for example purposes only,
    //      it is not intended to be used in a production environment.

    public enum KeychainError: Error {
        case itemNotFound
        case invalidItemFormat
        case unexpectedStatus(OSStatus)
    }

    // TODO: add delete function

    public static func save(item: String, key: String, identifier: String = "web3auth.tkey-ios") throws {
        let query: [String: AnyObject] = [
            kSecAttrService as String: identifier as AnyObject,
            kSecAttrAccount as String: key as AnyObject,
            kSecClass as String: kSecClassGenericPassword,
            kSecValueData as String: item.data(using: .utf8)! as AnyObject
        ]

        // First delete item if found
        var status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }

        // Add new item
        status = SecItemAdd(
            query as CFDictionary,
            nil
        )

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public static func fetch(key: String, identifier: String = "web3auth.tkey-ios") throws -> String {
        let query: [String: AnyObject] = [
            kSecAttrService as String: identifier as AnyObject,
            kSecAttrAccount as String: key as AnyObject,
            kSecClass as String: kSecClassGenericPassword,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue
        ]

        var itemCopy: AnyObject?
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &itemCopy
        )

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }

        guard let item = itemCopy as? Data else {
            throw KeychainError.invalidItemFormat
        }

        return  String(decoding: item, as: UTF8.self)
    }
}
