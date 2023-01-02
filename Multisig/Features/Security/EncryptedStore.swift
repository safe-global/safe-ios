//
//  CryptoCenter.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import CommonCrypto
import CryptoKit

typealias EthPrivateKey = Data

protocol EncryptedStore {
    func isInitialized() -> Bool
    func initializeKeyStore() throws
    func `import`(id: DataID, ethPrivateKey: EthPrivateKey) throws
    func delete(address: Address) throws

    /// Find private signer key.
    /// - parameter address: find key for this address
    /// - parameter password: application password. Can be nil, then the stored password is used
    /// - returns: String with hex encoded bytes of the private key or nil if key not found
    func find(dataID: DataID, password: String?) throws -> EthPrivateKey?
    func changePassword(from oldPassword: String, to newPassword: String) throws
    func changeSettings()
}

class DataID {
    let id: String
    let protectionClass: ProtectionClass

    public init(id: String, protectionClass: ProtectionClass = .sensitive) {
        self.id = id
        self.protectionClass = protectionClass
    }
}

enum ProtectionClass {
    case sensitive
    // for future use
    case data

    func service() -> String {
        switch self {
        case .data: return "global.safe.data.encrypted.data"
        case .sensitive: return "global.safe.sensitive.encrypted.data"
        }
    }
}
