//
// Created by Dirk Jäckel on 17.11.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import LocalAuthentication

class KeychainItemFactory {

    let protectionClass: ProtectionClass

    init(protectionClass: ProtectionClass) {
        self.protectionClass = protectionClass
    }

    func ecPubKey(publicKey: SecKey? = nil) -> KeychainItem {
        KeychainItem.ecPubKey(tag: ProtectedKeyStore.publicKeyTag, service: protectionClass.service(), publicKey: publicKey)
    }

    func generic(account: String, data: Data? = nil) -> KeychainItem {
        KeychainItem.generic(account: account, service: protectionClass.service(), data: data)
    }

    func enclaveKey(password: Data? = nil, access: SecAccessControlCreateFlags? = nil) -> KeychainItem {
        KeychainItem.enclaveKey(tag: ProtectedKeyStore.privateKEKTag, service: protectionClass.service(), password: password, access: access)
    }

    func ecKeyPair() -> KeychainItem {
        KeychainItem.ecKeyPair
    }
}

private let TAG_SERVICE_DELIMITER = ":"

enum KeychainItem {
    // Encrypted blob. Can be a password or a cec secret key
    case generic(account: String, service: String, data: Data? = nil)
    // Key stays in the Secure Enclave
    case enclaveKey(tag: String, service: String, password: Data? = nil, access: SecAccessControlCreateFlags? = nil)
    // Elliptic Curve Public Key
    case ecPubKey(tag: String, service: String, publicKey: SecKey? = nil)

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

        case let .enclaveKey(tag, service, password, _):

            result = [
                kSecClass: kSecClassKey,
                kSecAttrKeyClass: kSecAttrKeyClassPrivate,
                kSecAttrApplicationTag: tagWithService(tag, service).data(using: .utf8)!,
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecReturnRef: true
            ]

            if let context = LAContext(password: password) {
                result[kSecUseAuthenticationContext] = context
            }
        case let .ecPubKey(tag, service, _):
            result = [
                kSecClass: kSecClassKey,
                kSecAttrKeyClass: kSecAttrKeyClassPublic,
                kSecAttrApplicationTag: tagWithService(tag, service).data(using: .utf8)!,
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

        case let .enclaveKey(tag, service, password, access):
            let accessControl = try accessControl(flags: .privateKeyUsage.union(access!))

            let privateKeyAttrs: NSMutableDictionary = [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: tagWithService(tag, service).data(using: .utf8)!,
                kSecAttrAccessControl: accessControl
            ]
            if let context = LAContext(password: password) {
                privateKeyAttrs[kSecUseAuthenticationContext] = context
            } else {
                // In case password is worng
                return [:]
            }
            result = [
                kSecClass: kSecClassKey,
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits: 256,
                kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
                kSecPrivateKeyAttrs: privateKeyAttrs,
                kSecAttrKeyClass: kSecAttrKeyClassPrivate
                // why not kSecReturnRef: true?
            ]
        case .ecKeyPair:
            result = [
                kSecClass: kSecClassKey,
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits: 256,
                kSecAttrKeyClass: kSecAttrKeyClassPrivate
            ]
        case let .ecPubKey(tag, service, pubKey):
            result = [
                kSecClass: kSecClassKey,
                kSecAttrKeyClass: kSecAttrKeyClassPublic,
                kSecAttrApplicationTag: tagWithService(tag, service).data(using: .utf8)!,
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

    private func tagWithService(_ tag: String, _ service: String) -> String {
        tag + TAG_SERVICE_DELIMITER + service
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
