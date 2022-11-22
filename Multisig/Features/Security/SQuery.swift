//
// Created by Dirk Jäckel on 17.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import LocalAuthentication

enum SQuery {
    case generic(id: String, service: String = KeychainStorage.defaultService, encryptedData: Data? = nil)
    case ecPrivateKey(tag: String = KeychainStorage.sensitiveKekTag, password: Data? = nil)
    case ecPubKey(tag: String = KeychainStorage.sensitivePublicKeyTag, pubKeyData: SecKey? = nil)

    func queryData() -> NSDictionary {
        var result: NSMutableDictionary

        switch self {
        case let .generic(id, service, encryptedData):
            result = [
                kSecAttrService: service,
                kSecAttrAccount: id,
                kSecClass: kSecClassGenericPassword,
                kSecReturnAttributes: false,
                kSecReturnData: true,
            ]
            if let encryptedData = encryptedData {
                result[kSecValueData] = encryptedData
            }

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
        case let .ecPubKey(tag, pubKeyData):
            result = [
                kSecClass: kSecClassKey,
                kSecAttrKeyClass: kSecAttrKeyClassPublic,
                kSecAttrApplicationTag: tag.data(using: .utf8)!,
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecReturnRef: true,
            ]
            if let pubKeyData = pubKeyData {
                result[kSecValueRef] = pubKeyData
            }
        }

        return result
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

enum SItem {
    case generic(id: String, service: String, data: Data)
    case enclaveKey(tag: String = KeychainStorage.sensitiveKekTag)
    case ecKey(_ tag: String?)

    // applies access flags and password to any type of item
    func attributes(access: SecAccessControlCreateFlags? = nil, password: Data? = nil) throws -> NSDictionary {
        var result: NSMutableDictionary = [:]
        switch self {
        case let .generic(id, service, data):
            break

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
        case let .ecKey(tag):
            result = [
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits: 256,
                kSecAttrKeyClass: kSecAttrKeyClassPrivate
            ]
            break
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

enum SQueryError: Error {
    case invalidPasscode
    case notFound
}
