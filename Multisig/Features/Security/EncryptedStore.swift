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

typealias EthPrivateKey = String

protocol EncryptedStore {
    func initialSetup() throws
    func `import`(ethPrivateKey: EthPrivateKey) throws
    func delete(address: Address)

    /// Find private signer key.
    /// - parameter address: find key for this address
    /// - parameter password: application password. Can be nil, then the stored password is used
    /// - returns: String with hex encoded bytes of the private key or nil if key not found
    func find(address: Address, password: String?) throws -> EthPrivateKey?
    func changePassword(from oldPassword: String, to newPassword: String)
    func changeSettings()
}
