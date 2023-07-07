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

protocol EncryptedStore {
    func isInitialized() -> Bool
    func initializeKeyStore() throws
    func `import`(id: DataID, data: Data) throws
    func delete(id: DataID) throws

    /// Find private signer key.
    /// - parameter address: find key for this address
    /// - parameter password: application password. Can be nil, then the stored password is used
    /// - returns: String with hex encoded bytes of the private key or nil if key not found
    func find(dataID: DataID, password: String?, forceUnlock: Bool) throws -> Data?
    func changePassword(from oldPassword: String?, to newPassword: String?, useBiometry: Bool, keepUnlocked: Bool) throws

    func deleteAllKeys() throws
}

class DataID {
    let id: String
    
    public init(id: String) {
        self.id = id
    }
}

enum ProtectionClass {
    case sensitive
    case data

    func service() -> String {
        switch self {
        case .data: return "global.safe.data.encrypted.data"
        case .sensitive: return "global.safe.sensitive.encrypted.data"
        }
    }
}
