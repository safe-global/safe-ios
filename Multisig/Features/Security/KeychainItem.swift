//
// Created by Dirk Jäckel on 17.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import LocalAuthentication

<<<<<<<< HEAD:Multisig/Features/Security/KeychainStoreItem.swift
enum KeychainStoreItem {
|||||||| b64bd38aa:Multisig/Features/Security/ItemSearchQuery.swift
enum ItemSearchQuery {
========
enum KeychainItem {
>>>>>>>> dc8a62db2741d8c1a21db5410b135a4ed53d4274:Multisig/Features/Security/KeychainItem.swift
    // Encrypted blob. Can be a password or a cec secret key
    case generic(id: String, service: String, data: Data? = nil)

    // Key stays in the Secure Enclave
<<<<<<<< HEAD:Multisig/Features/Security/KeychainStoreItem.swift
    case enclaveKey(tag: String = KeychainStorage.sensitiveKekTag, password: Data? = nil, access: SecAccessControlCreateFlags? = nil)

|||||||| b64bd38aa:Multisig/Features/Security/ItemSearchQuery.swift
    case enclaveKey(tag: String = KeychainStorage.sensitiveKekTag, password: Data? = nil, access: SecAccessControlCreateFlags? = nil)
========
    case enclaveKey(tag: String = KeychainStorage.sensitivePrivateKekTag, password: Data? = nil, access: SecAccessControlCreateFlags? = nil)
>>>>>>>> dc8a62db2741d8c1a21db5410b135a4ed53d4274:Multisig/Features/Security/KeychainItem.swift
    // Elliptic Curve Public Key
    case ecPubKey(tag: String = KeychainStorage.sensitivePublicKeyTag, publicKey: SecKey? = nil)

    // Elliptic Curve Key pair
    case ecKeyPair

    func searchQuery() -> NSDictionary {
        var result: NSMutableDictionary

        switch self {
        case let .generic(id, service, _):
            result = [
                kSecAttrService: service,
                kSecAttrAccount: id,
                kSecClass: kSecClassGenericPassword,
                kSecReturnAttributes: false,
                kSecReturnData: true,
            ]

        case let .enclaveKey(tag, password, _):
            result = [
                kSecClass: kSecClassKey,
                kSecAttrKeyClass: kSecAttrKeyClassPrivate,
                kSecAttrApplicationTag: tag.data(using: .utf8)!,
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecReturnRef: true
            ]

            if let context = LAContext(password: password) {
                result[kSecUseAuthenticationContext] = context
            }
        case let .ecPubKey(tag, _):
            result = [
                kSecClass: kSecClassKey,
                kSecAttrKeyClass: kSecAttrKeyClassPublic,
                kSecAttrApplicationTag: tag.data(using: .utf8)!,
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecReturnRef: true,
            ]
        case .ecKeyPair:
            result = [:]
        }

        return result
    }

    func creationAttributes() throws -> NSDictionary {
        var result: NSMutableDictionary = [:]
        switch self {
        case let .generic(id, service, data):
            result = [
                kSecAttrService: service,
                kSecAttrAccount: id,
                kSecClass: kSecClassGenericPassword,
                kSecReturnAttributes: false,
                kSecReturnData: true,
            ]
            if let data = data {
                result[kSecValueData] = data
            }

        case let .enclaveKey(tag, password, access):
            let accessControl = try accessControl(flags: .privateKeyUsage.union(access!))

            let privateKeyAttrs: NSMutableDictionary = [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: tag.data(using: .utf8)!,
                kSecAttrAccessControl: accessControl
            ]
            if let context = LAContext(password: password) {
                privateKeyAttrs[kSecUseAuthenticationContext] = context
            }
            result = [
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits: 256,
                kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
                kSecPrivateKeyAttrs: privateKeyAttrs
                // why not kSecReturnRef: true?
            ]
        case .ecKeyPair:
            result = [
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits: 256,
                kSecAttrKeyClass: kSecAttrKeyClassPrivate
                // why not kSecReturnRef: true?
            ]
        case let .ecPubKey(tag, pubKey):
            result = [
                kSecClass: kSecClassKey,
                kSecAttrKeyClass: kSecAttrKeyClassPublic,
                kSecAttrApplicationTag: tag.data(using: .utf8)!,
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecReturnRef: true
            ]
            if let pubKey = pubKey {
                result[kSecValueRef] = pubKey
            }
        }
        return result
    }

    // create access control flags with params
    fileprivate func accessControl(flags: SecAccessControlCreateFlags) throws -> SecAccessControl {
        // SWIFT: can't extend SecAccessControl (compiler error that extensions of CF classes are not supported).

        var accessError: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleAfterFirstUnlock,
                flags,
                &accessError
        )
        else {
            throw accessError!.takeRetainedValue() as Error
        }
        return access
    }

}

<<<<<<<< HEAD:Multisig/Features/Security/KeychainStoreItem.swift
func ==(left: KeychainStoreItem, right: KeychainStoreItem) -> Bool {
    switch (left, right) {
    case (.ecKeyPair, .ecKeyPair): return true
    default: return false
    }
}

func !=(left: KeychainStoreItem, right: KeychainStoreItem) -> Bool {
    !(left == right)
}

|||||||| b64bd38aa:Multisig/Features/Security/ItemSearchQuery.swift
func ==(left: ItemSearchQuery, right: ItemSearchQuery) -> Bool {
    switch (left, right) {
    case (.ecKeyPair, .ecKeyPair): return true
    default: return false
    }
}

func !=(left: ItemSearchQuery, right: ItemSearchQuery) -> Bool {
    !(left == right)
}

========
>>>>>>>> dc8a62db2741d8c1a21db5410b135a4ed53d4274:Multisig/Features/Security/KeychainItem.swift
fileprivate extension LAContext {
    convenience init?(password: Data?) {
        guard let appPassword = password else {
            return nil
        }
        self.init()
        let success = setCredential(appPassword, type: .applicationPassword)
        guard success else {
            return nil
        }
    }
}
