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
    func find(address: Address, password: String) throws -> EthPrivateKey
    func verify()
    func changePassword(from oldPassword: String, to newPassword: String)
    func changeSettings()
}