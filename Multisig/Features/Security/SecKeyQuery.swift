//
// Created by Dirk Jäckel on 17.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import LocalAuthentication

enum SecKeyQuery {
    // use this whenever searching for  a key or password

    case generic(id: String, service: String = KeychainStorage.defaultService)
    case ecPrivateKey(tag: String = KeychainStorage.sensitiveKekTag, password: Data? = nil)
    case ecPubKey(tag: String = KeychainStorage.sensitivePublicKeyTag)

    func queryData() -> NSDictionary {
        var result: NSMutableDictionary

        switch self {
        case let .generic(id, service):
            result = [
                kSecAttrService: service,
                kSecAttrAccount: id,
                kSecClass: kSecClassGenericPassword,
                kSecReturnAttributes: false,
                kSecReturnData: true,
            ]

        case let .ecPrivateKey(tag, password):
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
        case let .ecPubKey(tag):
            result = [
                kSecClass: kSecClassKey,
                kSecAttrKeyClass: kSecAttrKeyClassPublic,
                kSecAttrApplicationTag: tag.data(using: .utf8)!,
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecReturnRef: true,
            ]
//            if let pubKeyData = pubKeyData {
//                result[kSecValueRef] = pubKeyData
//            }
        }

        return result
    }

}


enum SecKeyItem {
    // use this whenever creating a key or adding it to the keychain
    case generic(id: String, service: String = KeychainStorage.defaultService, data: Data)
    case enclaveKey(tag: String = KeychainStorage.sensitiveKekTag)
    case ecKeyPair(_ tag: String)
    case ecPrivateKey(tag: String, password: String)
    case ecPubKey(tag: String, pubKey: SecKey)

    // applies access flags and password to any type of item
    func attributes(access: SecAccessControlCreateFlags? = nil, password: Data? = nil) throws -> NSDictionary {
        var result: NSMutableDictionary = [:]
        switch self {
        case let .generic(id, service, data):
            result = [
                kSecAttrService: service,
                kSecAttrAccount: id,
                kSecClass: kSecClassGenericPassword,
                kSecReturnAttributes: false,
                kSecReturnData: true,
                kSecValueData: data
            ]

        case let .enclaveKey(tag):
            let accessControl = try accessControl(flags: .privateKeyUsage.union(access!))

            // create private key attributes
            var privateKeyAttrs: NSMutableDictionary = [
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

                // During creation of the keypair, the tag is not known. And there is actually two tags.
                // One for the public key and one for the private key.
        case let .ecKeyPair(tag):
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
                kSecReturnRef: true,
//                kSecValueRef: pubKey
            ]

            result[kSecValueRef] = pubKey

        case let .ecPrivateKey(tag, password):
            result = [
                kSecClass: kSecClassKey,
                kSecAttrKeyClass: kSecAttrKeyClassPrivate,
                kSecAttrApplicationTag: tag.data(using: .utf8)!,
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecReturnRef: true
            ]

            if let context = LAContext(password: password.data(using: .utf8)) {
                result[kSecUseAuthenticationContext] = context
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

enum SQueryError: Error {
    case invalidPasscode
    case notFound
}
