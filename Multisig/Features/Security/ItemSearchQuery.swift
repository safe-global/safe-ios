//
// Created by Dirk Jäckel on 17.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import LocalAuthentication

enum ItemSearchQuery {
    // use this whenever searching for  a key or password

    case generic(id: String, service: String = KeychainStorage.defaultService, data: Data? = nil)
    case enclaveKey(tag: String = KeychainStorage.sensitiveKekTag, password: Data? = nil)
    case ecPubKey(tag: String = KeychainStorage.sensitivePublicKeyTag, publicKey: SecKey? = nil)
    case ecKeyPair

    func createSearchQuery() -> NSDictionary {
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

        case let .enclaveKey(tag, password):
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

    func createAttributesForItem(access: SecAccessControlCreateFlags? = nil, password: Data? = nil) throws -> NSDictionary {
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

        case let .enclaveKey(tag, password):
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
            ]
        case .ecKeyPair:
            result = [
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits: 256,
                kSecAttrKeyClass: kSecAttrKeyClassPrivate
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