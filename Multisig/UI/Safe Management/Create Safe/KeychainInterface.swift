import Foundation
import Security

public protocol KeychainInterface {
    func save(item: String, key: String) throws
    func fetch(key: String) throws -> String
}

enum KeychainError: Error {
    case itemNotFound
    case invalidItemFormat
    case unexpectedStatus(OSStatus)
}

public class SimpleKeychainInterface: KeychainInterface {

    // TODO: add delete function

    let identifier: String

    init(identifier: String) {
        self.identifier = identifier
    }

    public func save(item: String, key: String) throws {
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

    public func fetch(key: String) throws -> String {
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
