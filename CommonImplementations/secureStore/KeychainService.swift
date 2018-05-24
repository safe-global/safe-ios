//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

public enum KeychainError: Error {

    case unexpectedPasswordData
    case unexpectedMnemonicData
    // https://www.osstatus.com
    case unhandledError(status: String)

}

public final class KeychainService: SecureStore {

    public func save(data: Data, forKey: String) throws {

    }

    public func data(forKey: String) throws -> Data? {
        return nil
    }

    public func removeData(forKey: String) throws {

    }


//    private static let defaultServiceName = "pm.gnosis.safe"
//    private let passwordServiceName: String
//    private let mnemonicServiceName: String
//
//    public convenience init() {
//        self.init(identifier: KeychainService.defaultServiceName)
//    }
//
//    public init(identifier: String) {
//        passwordServiceName = identifier + ".password"
//        mnemonicServiceName = identifier + ".mnemonic"
//    }
//
//    private func get(query: [String: Any]) throws -> CFTypeRef? {
//        var item: CFTypeRef?
//        let status = SecItemCopyMatching(query as CFDictionary, &item)
//        guard status != errSecItemNotFound else { return nil }
//        guard status == errSecSuccess else {
//            throw KeychainError.unhandledError(status: securityError(status))
//        }
//        return item
//    }
//
//    private func securityError(_ status: OSStatus) -> String {
//        if #available(iOS 11.3, *) {
//            if let str = SecCopyErrorMessageString(status, nil) as String? {
//                return str
//            }
//        }
//        return String(describing: status)
//    }
//
//    private func add(query: [String: Any]) throws {
//        let status = SecItemAdd(query as CFDictionary, nil)
//        guard status == errSecSuccess else {
//            throw KeychainError.unhandledError(status: securityError(status))
//        }
//    }
//
//    private func remove(query: [String: Any]) throws {
//        let status = SecItemDelete(query as CFDictionary)
//        guard status == errSecSuccess || status == errSecItemNotFound else {
//            throw KeychainError.unhandledError(status: securityError(status))
//        }
//    }
//
//    // MARK: - Password
//
//    public func password() throws -> String? {
//        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
//                                    kSecAttrService as String: passwordServiceName,
//                                    kSecMatchLimit as String: kSecMatchLimitOne,
//                                    kSecReturnAttributes as String: true,
//                                    kSecReturnData as String: true]
//
//
//        guard let existingItem = try get(query: query) as? [String: Any],
//            let passwordData = existingItem[kSecValueData as String] as? Data,
//            let password = String(data: passwordData, encoding: String.Encoding.utf8)
//            else {
//                return nil
//        }
//        return password
//    }
//
//    public func savePassword(_ password: String) throws {
//        guard let passwordData = password.data(using: String.Encoding.utf8) else {
//            throw KeychainError.unexpectedPasswordData
//        }
//        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
//                                    kSecAttrService as String: passwordServiceName,
//                                    kSecValueData as String: passwordData]
//        try add(query: query)
//    }
//
//    public func removePassword() throws {
//        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
//                                    kSecAttrService as String: passwordServiceName]
//        try remove(query: query)
//    }
//
//    // MARK: - Private Key
//
//    public func privateKey() throws -> PrivateKey? {
//        let query: [String: Any] = [kSecClass as String: kSecClassKey,
//                                    kSecMatchLimit as String: kSecMatchLimitOne,
//                                    kSecReturnAttributes as String: true,
//                                    kSecReturnData as String: true]
//        guard let existingItem = try get(query: query) as? [String: Any],
//            let data = existingItem[kSecValueData as String] as? Data else { return nil }
//        return PrivateKey(data: data)
//    }
//
//    public func savePrivateKey(_ privateKey: PrivateKey) throws {
//        let query: [String: Any] = [kSecClass as String: kSecClassKey,
//                                    kSecValueData as String: privateKey.data]
//        try add(query: query)
//    }
//
//    public func removePrivateKey() throws {
//        let query: [String: Any] = [kSecClass as String: kSecClassKey]
//        try remove(query: query)
//    }
//
//    // MARK: - Mnemonic
//
//    public func mnemonic() throws -> Mnemonic? {
//        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
//                                    kSecAttrService as String: mnemonicServiceName,
//                                    kSecMatchLimit as String: kSecMatchLimitOne,
//                                    kSecReturnAttributes as String: true,
//                                    kSecReturnData as String: true]
//        guard let existingItem = try get(query: query) as? [String: Any],
//            let mnemonicData = existingItem[kSecValueData as String] as? Data,
//            let mnemonicString = String(data: mnemonicData, encoding: String.Encoding.utf8)
//            else {
//                return nil
//        }
//        return Mnemonic(mnemonicString)
//    }
//
//    public func saveMnemonic(_ mnemonic: Mnemonic) throws {
//        guard let mnemonicData = mnemonic.string().data(using: String.Encoding.utf8) else {
//            throw KeychainError.unexpectedMnemonicData
//        }
//        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
//                                    kSecAttrService as String: mnemonicServiceName,
//                                    kSecValueData as String: mnemonicData]
//        try add(query: query)
//    }
//
//    public func removeMnemonic() throws {
//        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
//                                    kSecAttrService as String: mnemonicServiceName]
//        try remove(query: query)
//    }

}
